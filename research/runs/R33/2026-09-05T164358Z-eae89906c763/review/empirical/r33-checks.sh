#!/usr/bin/env bash
# R33 property-and-snapshot-testing — synthesizer empirical check (revision 4).
# Verifies claims made by raw/codex.md and raw/opus.md. Implements nothing:
# no crate is scaffolded, no tool installed, no workspace or lockfile created.
#
# Revision 4 changes, forced by the revision-3 audit (review/audit-codex.md),
# which found a ratio-stability claim that no check derived:
#   * check 4 now COMPUTES each of the six ratios the decision states, from the
#     two fetched figures it comes from, prints the quotient to four decimal
#     places beside its one-decimal rounding, and asserts a dominance FLOOR per
#     ratio. A floor is the durable claim: the counters drift daily and in both
#     directions, so an exact live value cannot be asserted, but "insta leads
#     snapbox by more than 5x on 90-day downloads" can, and it fails if adoption
#     actually reverses.
#   * check 4b is NEW. It recomputes all twelve ratio values (six ratios on each
#     of two dates) from two committed snapshots of the crates.io counters,
#     asserts every one of them EXACTLY, and prints the one-decimal moved/held
#     comparison between the dates. Both inputs are static files, so this check
#     is deterministic and reproduces byte-for-byte on any day.
#     It reads the snapshots and NOT research/topics/.../evidence/*.log, because
#     that path holds the publisher's copy of whichever revision is current: a
#     check reading it would compare the 2026-09-10 figures against whatever was
#     published last and fail on every rerun after publication.
#   * check 4b also asserts that review/DECISION.md carries each of those twelve
#     computed values, so a ratio can no longer be restated in prose without a
#     check deriving it. That assertion is between two committed files and is
#     what the revision-3 audit's finding would have caught.
#
# Revision 3 changes:
#   * check 14 REMOVED. It existed only to test candidates against a strict
#     all-dependencies-dual reading of the `license` fitness gate. The owner's
#     ruling of 2026-09-12 (Q4 as superseded by Q7.B) strikes licence-compat
#     evaluation for every dependency and tool, so that check no longer tests
#     anything this decision asks. Checks 1-13 (with 9b and 11b) are unchanged,
#     and every "(check N)" citation still names the section it always named.
#   * the User-Agent header carries the repository URL instead of a personal
#     email address (standing evidence rule; R42 revision 7 set the precedent).
#     No log ever contained the address; it was sent on the wire only.
#   * checks 3 and 7 keep their licence reads. They are retained as recorded
#     fact alongside each crate's MSRV, edition and default features, and no
#     gate verdict in the decision now rests on them.
#
# Revision 2 changes, all forced by the revision-1 audit (review/audit-codex.r1.md):
#   * `set -o pipefail` plus explicit per-command status capture, so a failing
#     command in a pipeline can no longer be masked by a succeeding one;
#   * every check asserts on expected content (expect_content / expect_absent /
#     expect_status), keeps a failure counter, and the script exits with it, so
#     the script's exit status means something;
#   * check 11 now reads docs/port/TS_PORT_DECISIONS.md (the path that exists at
#     the pin) instead of the repository-root path that does not;
#   * follow-ups 9b, 11b and 13, previously run by hand, are part of the script;
#   * check 14 (new in revision 2, REMOVED IN REVISION 3) walked the declared,
#     non-optional, normal dependencies of the four candidate crates and
#     reported each dependency's declared licence.
#
# Run from anywhere: every repository path is resolved from this script's own
# location, so the working directory does not change the result.
set -u
set -o pipefail

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(git -C "$SELF_DIR" rev-parse --show-toplevel)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

UA='User-Agent: rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'
PY=~/c/py-launch-blueprint
TS=~/c/ts-launch-blueprint
PYPIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TSPIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00

# The version each claim in review/DECISION.md is made about. Checks that assert
# a licence or an MSRV read the pinned version's record, not "whatever is newest",
# so a later release cannot silently change what the check proves.
PINS="proptest=1.11.0 quickcheck=1.1.0 insta=1.48.0 cargo-insta=1.48.0 snapbox=1.2.2 expect-test=1.5.1 proptest-derive=0.8.0"

fail=0
hdr() { echo; echo "===== CHECK $1 — $2 ====="; echo "-- run at $(date -u +%Y-%m-%dT%H:%M:%SZ)"; }

# expect_status <label> <expected-exit> <observed-exit>
expect_status() {
  if [ "$2" = "$3" ]; then
    echo "  STATUS OK   $1: exit=$3 (expected $2)"
  else
    echo "  STATUS FAIL $1: exit=$3 (expected $2)"; fail=$((fail + 1))
  fi
}
# expect_content <label> <file> <extended-regex>
expect_content() {
  if grep -qE -- "$3" "$2"; then
    echo "  ASSERT OK   $1: /$3/ present"
  else
    echo "  ASSERT FAIL $1: /$3/ absent"; fail=$((fail + 1))
  fi
}
# expect_absent <label> <file> <extended-regex>
expect_absent() {
  if grep -qE -- "$3" "$2"; then
    echo "  ASSERT FAIL $1: /$3/ present but must be absent"; fail=$((fail + 1))
  else
    echo "  ASSERT OK   $1: /$3/ absent"
  fi
}
pin_of() { for kv in $PINS; do case "$kv" in "$1="*) echo "${kv#*=}"; return 0;; esac; done; return 1; }

# --- ratio arithmetic, shared by checks 4 and 4b -----------------------------
# Every ratio this decision states is DERIVED here from the two crates.io
# figures it comes from. Nothing downstream may restate a ratio that this file
# did not compute. `single` prints each quotient to four decimal places beside
# its one-decimal rounding, then a FLOOR verdict; `compare` prints, per ratio,
# whether the one-decimal value differs between two sets of figures.
# A figures file is the six `  <crate>: recent_downloads=N downloads=N
# reverse_deps=N` lines emitted by check 4; comment lines are ignored.
cat > "$WORK/ratios.py" <<'PYEOF'
import sys

# id, kind, numerator crate, denominator crate, crates.io field, dominance floor.
# The floor is the claim the decision makes and the only thing asserted against
# LIVE figures: counters move daily and in both directions, so an exact live
# value is not assertable, but a dominance relationship is.
PAIRS = [
    ("insta/snapbox",       "90d-downloads", "insta",    "snapbox",     "recent_downloads",  5.0),
    ("insta/snapbox",       "reverse-deps",  "insta",    "snapbox",     "reverse_deps",     20.0),
    ("insta/expect-test",   "90d-downloads", "insta",    "expect-test", "recent_downloads",  3.0),
    ("insta/expect-test",   "reverse-deps",  "insta",    "expect-test", "reverse_deps",     10.0),
    ("proptest/quickcheck", "90d-downloads", "proptest", "quickcheck",  "recent_downloads",  3.0),
    ("proptest/quickcheck", "reverse-deps",  "proptest", "quickcheck",  "reverse_deps",      5.0),
]

def load(path):
    figs = {}
    for line in open(path):
        s = line.strip()
        if not s or s.startswith("#") or "recent_downloads=" not in s or ":" not in s:
            continue
        name, rest = s.split(":", 1)
        kv = dict(p.split("=", 1) for p in rest.split())
        figs[name.strip()] = {k: int(v) for k, v in kv.items()}
    missing = {c for _, _, a, b, _, _ in PAIRS for c in (a, b)} - set(figs)
    if missing:
        raise SystemExit("figures file %s is missing crates: %s" % (path, sorted(missing)))
    return figs

mode = sys.argv[1]
if mode == "single":
    label, path = sys.argv[2], sys.argv[3]
    figs = load(path)
    for ident, kind, a, b, field, floor in PAIRS:
        n, d = figs[a][field], figs[b][field]
        q = n / d
        print("  RATIO %s %s %s = %.4f -> %.1fx  (%d / %d)" % (label, ident, kind, q, q, n, d))
        # STRICT `>`: the decision's wording is "leads by more than <floor>x",
        # so a quotient exactly equal to the floor must not pass.
        print("  FLOOR %s %s %s > %.1f : %s  (%.4f)"
              % (label, ident, kind, floor, "OK" if q > floor else "FAIL", q))
elif mode == "compare":
    pa, la, pb, lb = sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
    fa, fb = load(pa), load(pb)
    moved = held = 0
    for ident, kind, a, b, field, _ in PAIRS:
        qa = fa[a][field] / fa[b][field]
        qb = fb[a][field] / fb[b][field]
        verdict = "moved" if "%.1f" % qa != "%.1f" % qb else "held"
        moved, held = (moved + 1, held) if verdict == "moved" else (moved, held + 1)
        print("  MOVE %s %s: %s %.1fx -> %s %.1fx : %s" % (ident, kind, la, qa, lb, qb, verdict))
    print("  one-decimal comparison %s -> %s: moved=%d held=%d of %d" % (la, lb, moved, held, len(PAIRS)))
else:
    raise SystemExit("unknown mode %r" % mode)
PYEOF

# The six ratios, as "<id> <kind> <floor>", for the assertion loops below.
RATIO_IDS='insta/snapbox|90d-downloads|5.0
insta/snapbox|reverse-deps|20.0
insta/expect-test|90d-downloads|3.0
insta/expect-test|reverse-deps|10.0
proptest/quickcheck|90d-downloads|3.0
proptest/quickcheck|reverse-deps|5.0'

# assert_floors <figures-label> <ratios-output-file>
# Asserts, for each of the six ratios, that ratios.py printed a FLOOR verdict of
# OK. `fail` must increment in this shell, so the loop reads a file rather than
# a pipe (a piped `while` runs in a subshell and would discard the counter).
assert_floors() {
  local label="$1" out="$2" ident kind floor efloor
  printf '%s\n' "$RATIO_IDS" > "$WORK/ratio-ids.txt"
  while IFS='|' read -r ident kind floor; do
    [ -n "$ident" ] || continue
    efloor=$(printf '%s' "$floor" | sed 's/\./\\./g')
    expect_content "$label: $ident $kind leads by more than ${floor}x" "$out" \
      "^  FLOOR $label $ident $kind > $efloor : OK"
  done < "$WORK/ratio-ids.txt"
}

hdr 1 "toolchain and host"
rustc --version > "$WORK/rustc.txt" 2>&1; expect_status "rustc --version" 0 $?
cat "$WORK/rustc.txt"; expect_content "rustc is a released version" "$WORK/rustc.txt" '^rustc 1\.[0-9]+\.[0-9]+'
cargo --version > "$WORK/cargo.txt" 2>&1; expect_status "cargo --version" 0 $?
cat "$WORK/cargo.txt"; expect_content "cargo is a released version" "$WORK/cargo.txt" '^cargo 1\.[0-9]+\.[0-9]+'
echo "os: macOS $(sw_vers -productVersion) $(uname -m)"
echo "note: the template does not exist yet; no Rust workspace is built or resolved here."

hdr 2 "current stable Rust (msrv floor input)"
curl -s --max-time 30 https://static.rust-lang.org/dist/channel-rust-stable.toml -o "$WORK/stable.toml"
expect_status "GET channel-rust-stable.toml" 0 $?
grep -m1 -A2 '^\[pkg.rust\]' "$WORK/stable.toml"; expect_status "grep [pkg.rust]" 0 $?
expect_content "a stable version line is present" "$WORK/stable.toml" '^version = "1\.[0-9]+\.[0-9]+'

hdr 3 "crates.io — the pinned version's licence, rust_version, edition (plus newest unyanked)"
for c in proptest quickcheck insta cargo-insta snapbox expect-test proptest-derive; do
  pin=$(pin_of "$c")
  code=$(curl -s --max-time 30 -H "$UA" -o "$WORK/$c-pin.json" -w '%{http_code}' "https://crates.io/api/v1/crates/$c/$pin")
  echo "GET https://crates.io/api/v1/crates/$c/$pin -> HTTP $code"
  expect_status "crates.io $c $pin is HTTP 200" 200 "$code"
  code=$(curl -s --max-time 30 -H "$UA" -o "$WORK/$c-versions.json" -w '%{http_code}' "https://crates.io/api/v1/crates/$c/versions")
  echo "GET https://crates.io/api/v1/crates/$c/versions -> HTTP $code"
  expect_status "crates.io $c versions is HTTP 200" 200 "$code"
  python3 - "$c" "$pin" "$WORK" > "$WORK/$c-line.txt" <<'PYEOF'
import json, sys
c, pin, work = sys.argv[1], sys.argv[2], sys.argv[3]
v = json.load(open(f"{work}/{c}-pin.json"))["version"]
print(f"  {c}: PINNED num={v['num']} created_at={v['created_at']} license={v['license']!r} "
      f"rust_version={v.get('rust_version')!r} edition={v.get('edition')!r} yanked={v['yanked']}")
d = json.load(open(f"{work}/{c}-versions.json"))
n = [x for x in d["versions"] if not x["yanked"]][0]
same = "same as pinned" if n["num"] == pin else f"DIFFERS from pin {pin}"
print(f"  {c}: newest-unyanked num={n['num']} license={n['license']!r} rust_version={n.get('rust_version')!r} ({same})")
PYEOF
  expect_status "parse $c version records" 0 $?
  cat "$WORK/$c-line.txt"
  case "$c" in
    insta|cargo-insta) expect_content "$c $pin declares Apache-2.0 alone" "$WORK/$c-line.txt" "PINNED num=$pin .*license='Apache-2\.0'" ;;
    quickcheck)        expect_content "$c $pin declares Unlicense OR MIT"  "$WORK/$c-line.txt" "PINNED num=$pin .*license='Unlicense OR MIT'" ;;
    *)                 expect_content "$c $pin declares MIT OR Apache-2.0" "$WORK/$c-line.txt" "PINNED num=$pin .*license='MIT OR Apache-2\.0'" ;;
  esac
  sleep 1
done

hdr 4 "crates.io — download and reverse-dependency figures (VOLATILE: counters move daily)"
for c in proptest quickcheck insta cargo-insta snapbox expect-test; do
  curl -s --max-time 30 -H "$UA" -o "$WORK/$c.json" "https://crates.io/api/v1/crates/$c"
  expect_status "GET crates.io/$c" 0 $?
  curl -s --max-time 30 -H "$UA" -o "$WORK/$c-rd.json" "https://crates.io/api/v1/crates/$c/reverse_dependencies?per_page=1"
  expect_status "GET crates.io/$c reverse_dependencies" 0 $?
  python3 - "$c" "$WORK" > "$WORK/$c-figs.txt" <<'PYEOF'
import json, sys
c, work = sys.argv[1], sys.argv[2]
d = json.load(open(f"{work}/{c}.json"))["crate"]
try:
    rd = json.load(open(f"{work}/{c}-rd.json"))["meta"]["total"]
except Exception as e:
    rd = f"unavailable ({e})"
print(f"  {c}: recent_downloads={d['recent_downloads']} downloads={d['downloads']} reverse_deps={rd}")
PYEOF
  expect_status "parse $c figures" 0 $?
  cat "$WORK/$c-figs.txt"
  expect_content "$c figures are numeric" "$WORK/$c-figs.txt" 'recent_downloads=[0-9]+ downloads=[0-9]+ reverse_deps=[0-9]+'
  sleep 1
done

echo
echo "-- the six ratios, DERIVED from the figures just fetched (VOLATILE values,"
echo "   durable floors). The quotient is printed to four decimal places beside its"
echo "   one-decimal rounding so the rounding is auditable. Only the FLOOR lines are"
echo "   asserted: an exact live value would be a claim that expires overnight."
cat "$WORK"/proptest-figs.txt "$WORK"/quickcheck-figs.txt "$WORK"/insta-figs.txt \
    "$WORK"/cargo-insta-figs.txt "$WORK"/snapbox-figs.txt "$WORK"/expect-test-figs.txt \
    > "$WORK/figs-live.txt"
expect_status "collect the six live figure lines" 0 $?
python3 "$WORK/ratios.py" single live "$WORK/figs-live.txt" > "$WORK/ratios-live.txt"
expect_status "derive the six live ratios" 0 $?
cat "$WORK/ratios-live.txt"
expect_content "every live ratio is printed in derived form" "$WORK/ratios-live.txt" \
  '^  RATIO live [a-z/-]+ [a-z0-9-]+ = [0-9]+\.[0-9]{4} -> [0-9]+\.[0-9]x  \([0-9]+ / [0-9]+\)$'
assert_floors live "$WORK/ratios-live.txt"

hdr 4b "the same six ratios recomputed from two COMMITTED snapshots, and the stability comparison"
echo "-- Inputs are static files in this run's evidence directory, so this section is"
echo "   deterministic: apart from its own '-- run at' header it prints identical text"
echo "   on any day and on any machine."
BASE10="$SELF_DIR/../evidence/adoption-figures-2026-09-10.txt"
BASE13="$SELF_DIR/../evidence/adoption-figures-2026-09-13.txt"
DEC="$SELF_DIR/../DECISION.md"
for f in "$BASE10" "$BASE13" "$DEC"; do
  test -f "$f"; expect_status "input exists: ${f##*/}" 0 $?
done
echo "-- provenance headers of the two snapshots (file names only: an absolute path"
echo "   would make this section machine-specific)"
for f in "$BASE10" "$BASE13"; do
  echo "  [${f##*/}]"
  grep -E '^# (source-path|source-sha256|source-run|extracted):' "$f"
  expect_status "${f##*/} carries provenance headers" 0 $?
done
expect_content "the 2026-09-10 snapshot names the published revision-2 log" "$BASE10" \
  '^# source-sha256: 33c4358489d43edf46b30e37f7a8f5ff465f99f22ea3058e99604d6d40115f6b$'
expect_content "the 2026-09-13 snapshot names the run at 07:25Z" "$BASE13" \
  '^# source-run: 2026-09-13T07:25Z'
for lbl in 2026-09-10 2026-09-13; do
  case "$lbl" in 2026-09-10) src="$BASE10" ;; *) src="$BASE13" ;; esac
  python3 "$WORK/ratios.py" single "$lbl" "$src" > "$WORK/ratios-$lbl.txt"
  expect_status "derive the six $lbl ratios" 0 $?
  cat "$WORK/ratios-$lbl.txt"
  assert_floors "$lbl" "$WORK/ratios-$lbl.txt"
done
echo "-- each ratio's exact value on each date, asserted (both inputs are immutable)"
for spec in \
  '2026-09-10|insta/snapbox|90d-downloads|8.2828|8.3' \
  '2026-09-10|insta/snapbox|reverse-deps|28.1026|28.1' \
  '2026-09-10|insta/expect-test|90d-downloads|3.6009|3.6' \
  '2026-09-10|insta/expect-test|reverse-deps|14.0064|14.0' \
  '2026-09-10|proptest/quickcheck|90d-downloads|4.4145|4.4' \
  '2026-09-10|proptest/quickcheck|reverse-deps|6.7630|6.8' \
  '2026-09-13|insta/snapbox|90d-downloads|8.2490|8.2' \
  '2026-09-13|insta/snapbox|reverse-deps|28.2051|28.2' \
  '2026-09-13|insta/expect-test|90d-downloads|3.5890|3.6' \
  '2026-09-13|insta/expect-test|reverse-deps|14.0575|14.1' \
  '2026-09-13|proptest/quickcheck|90d-downloads|4.3973|4.4' \
  '2026-09-13|proptest/quickcheck|reverse-deps|6.8021|6.8' ; do
  IFS='|' read -r lbl ident kind exact rounded <<< "$spec"
  expect_content "$lbl $ident $kind computes to ${exact} (${rounded}x)" "$WORK/ratios-$lbl.txt" \
    "^  RATIO $lbl $ident $kind = ${exact//./\\.} -> ${rounded//./\\.}x"
  expect_content "review/DECISION.md pairs ${exact} with ${rounded}x for $lbl $ident $kind" "$DEC" \
    "${exact//./\\.}.*${rounded//./\\.}"
done
echo "-- which ratios moved at one decimal place between the two dates"
python3 "$WORK/ratios.py" compare "$BASE10" 2026-09-10 "$BASE13" 2026-09-13 > "$WORK/ratios-compare.txt"
expect_status "compare the two dates" 0 $?
cat "$WORK/ratios-compare.txt"
for spec in \
  'insta/snapbox|90d-downloads|8.3|8.2|moved' \
  'insta/snapbox|reverse-deps|28.1|28.2|moved' \
  'insta/expect-test|90d-downloads|3.6|3.6|held' \
  'insta/expect-test|reverse-deps|14.0|14.1|moved' \
  'proptest/quickcheck|90d-downloads|4.4|4.4|held' \
  'proptest/quickcheck|reverse-deps|6.8|6.8|held' ; do
  IFS='|' read -r ident kind a b verdict <<< "$spec"
  expect_content "$ident $kind went ${a}x -> ${b}x and is '$verdict'" "$WORK/ratios-compare.txt" \
    "^  MOVE $ident $kind: 2026-09-10 ${a//./\\.}x -> 2026-09-13 ${b//./\\.}x : $verdict$"
done
expect_content "three of the six moved at one decimal and three held" "$WORK/ratios-compare.txt" \
  '^  one-decimal comparison 2026-09-10 -> 2026-09-13: moved=3 held=3 of 6$'
echo "-- the counters move in BOTH directions: cargo-insta's 90-day downloads FELL"
for f in "$BASE10" "$BASE13"; do
  printf '  [%s] ' "${f##*/}"; grep -E '^  cargo-insta: ' "$f"
  expect_status "read cargo-insta in ${f##*/}" 0 $?
done
expect_content "cargo-insta 90-day downloads were 204308 on 2026-09-10" "$BASE10" \
  '^  cargo-insta: recent_downloads=204308 '
expect_content "cargo-insta 90-day downloads were 199628 on 2026-09-13 (a fall)" "$BASE13" \
  '^  cargo-insta: recent_downloads=199628 '

hdr 5 "RustSec package pages, with two known-advisory controls"
: > "$WORK/rustsec.txt"
for c in proptest quickcheck insta cargo-insta snapbox expect-test proptest-derive time atty; do
  code=$(curl -s -o /dev/null --max-time 30 -w '%{http_code}' "https://rustsec.org/packages/$c.html")
  printf '  %-16s %s\n' "$c" "$code" | tee -a "$WORK/rustsec.txt"
done
echo "  controls 'time' and 'atty' are crates with published advisories; a 200 there with 404 elsewhere"
echo "  shows rustsec.org publishes a package page only when an advisory exists."
for c in proptest quickcheck insta cargo-insta snapbox expect-test proptest-derive; do
  expect_content "$c has no RustSec page (404)" "$WORK/rustsec.txt" "^  $c +404$"
done
expect_content "control 'time' has a RustSec page (200)" "$WORK/rustsec.txt" '^  time +200$'
expect_content "control 'atty' has a RustSec page (200)" "$WORK/rustsec.txt" '^  atty +200$'

hdr 6 "first-party CI OS matrices (fitness gate 4)"
for spec in "proptest-rs/proptest .github/workflows/rust.yml" "mitsuhiko/insta .github/workflows/tests.yml" "assert-rs/snapbox .github/workflows/ci.yml"; do
  set -- $spec
  echo "--- $1 $2"
  gh api "repos/$1/contents/$2" --jq '.content' > "$WORK/wf.b64" 2>"$WORK/wf.err"; st=$?
  expect_status "gh api repos/$1/contents/$2" 0 "$st"
  if [ "$st" -ne 0 ]; then cat "$WORK/wf.err"; continue; fi
  base64 -d < "$WORK/wf.b64" > "$WORK/wf.yml"; expect_status "base64 -d workflow" 0 $?
  grep -n -i "runs-on\|os:\|macos\|ubuntu\|windows" "$WORK/wf.yml" | head -20
  case "$1" in
    proptest-rs/proptest)
      expect_content "proptest CI runs ubuntu-24.04" "$WORK/wf.yml" 'ubuntu-24\.04'
      expect_absent  "proptest CI has no macOS leg"  "$WORK/wf.yml" 'macos'
      expect_absent  "proptest CI has no Windows leg" "$WORK/wf.yml" 'windows' ;;
    mitsuhiko/insta)
      expect_content "insta CI runs ubuntu-latest"  "$WORK/wf.yml" 'ubuntu-latest'
      expect_content "insta CI runs macos-latest"   "$WORK/wf.yml" 'macos-latest'
      expect_content "insta CI runs windows-latest" "$WORK/wf.yml" 'windows-latest' ;;
    assert-rs/snapbox)
      expect_content "snapbox CI runs ubuntu-latest"  "$WORK/wf.yml" 'ubuntu-latest'
      expect_content "snapbox CI runs macos-latest"   "$WORK/wf.yml" 'macos-latest'
      expect_content "snapbox CI runs windows-latest" "$WORK/wf.yml" 'windows-latest' ;;
  esac
done

hdr 7 "insta manifest — licence field and default features (docs.rs correction)"
curl -s --max-time 30 https://raw.githubusercontent.com/mitsuhiko/insta/master/insta/Cargo.toml -o "$WORK/insta-manifest.toml"
expect_status "GET mitsuhiko/insta insta/Cargo.toml" 0 $?
sed -n '1,45p' "$WORK/insta-manifest.toml"
expect_content "insta's own manifest declares Apache-2.0" "$WORK/insta-manifest.toml" '^license = "Apache-2\.0"'
expect_content "insta default features are colors only"   "$WORK/insta-manifest.toml" '^default = \["colors"\]'
echo "--- workspace manifest: members and prebuilt targets"
curl -s --max-time 30 https://raw.githubusercontent.com/mitsuhiko/insta/master/Cargo.toml -o "$WORK/insta-ws.toml"
expect_status "GET mitsuhiko/insta Cargo.toml" 0 $?
sed -n '1,40p' "$WORK/insta-ws.toml"
expect_content "cargo-insta is a workspace member"        "$WORK/insta-ws.toml" 'members = \["cargo-insta"\]'
expect_content "dist targets include aarch64-apple-darwin" "$WORK/insta-ws.toml" 'aarch64-apple-darwin'
expect_content "dist targets include x86_64-unknown-linux-gnu" "$WORK/insta-ws.toml" 'x86_64-unknown-linux-gnu'

hdr 8 "proptest manifest at HEAD — rust-version vs the published 1.11.0 value"
curl -s --max-time 30 https://raw.githubusercontent.com/proptest-rs/proptest/master/proptest/Cargo.toml -o "$WORK/proptest-manifest.toml"
expect_status "GET proptest-rs/proptest proptest/Cargo.toml" 0 $?
grep -n -E "^(name|version|edition|rust-version|license)|^\[features\]|^default =" "$WORK/proptest-manifest.toml" | head -20
expect_status "grep proptest manifest fields" 0 $?
expect_content "HEAD declares rust-version 1.86" "$WORK/proptest-manifest.toml" '^rust-version = "1\.86"'
expect_content "HEAD default features"           "$WORK/proptest-manifest.toml" '^default = \["std", "fork", "timeout", "bit-set"\]'

hdr 9 "clap documentation — the determinism pins the B2 architecture depends on"
code=$(curl -s --max-time 40 -H "$UA" https://docs.rs/clap/latest/clap/builder/struct.StyledStr.html -o "$WORK/styledstr.html" -w '%{http_code}')
echo "StyledStr HTTP $code"; expect_status "docs.rs StyledStr is HTTP 200" 200 "$code"
python3 - "$WORK/styledstr.html" 'Color-unaware printing' 'Never uses coloring' 'ansi(' > "$WORK/styledstr.txt" <<'PYEOF'
import re, html, sys
t = open(sys.argv[1], errors='replace').read()
t = re.sub('<[^>]+>', '', t); t = html.unescape(t); t = ' '.join(t.split())
for pat in sys.argv[2:]:
    i = t.find(pat)
    print(f"  {pat!r}: {'FOUND' if i >= 0 else 'NOT FOUND'}",
          ('...' + ' '.join(t[max(0, i - 120):i + 120].split())) if i >= 0 else '')
PYEOF
expect_status "scan StyledStr page" 0 $?
cat "$WORK/styledstr.txt"
expect_content "StyledStr documents color-unaware Display" "$WORK/styledstr.txt" "'Color-unaware printing': FOUND"
expect_content "StyledStr documents 'Never uses coloring'" "$WORK/styledstr.txt" "'Never uses coloring': FOUND"
expect_content "StyledStr offers an opt-in ansi() method"   "$WORK/styledstr.txt" "'ansi\(': FOUND"
code=$(curl -s --max-time 40 -H "$UA" https://docs.rs/clap/latest/clap/struct.Command.html -o "$WORK/command.html" -w '%{http_code}')
echo "Command HTTP $code"; expect_status "docs.rs Command is HTTP 200" 200 "$code"
python3 - "$WORK/command.html" render_long_help get_subcommands term_width > "$WORK/command.txt" <<'PYEOF'
import re, html, sys
t = open(sys.argv[1], errors='replace').read()
t = re.sub('<[^>]+>', '', t); t = html.unescape(t); t = ' '.join(t.split())
for pat in sys.argv[2:]:
    i = t.find(pat)
    print(f"  {pat!r}: {'FOUND' if i >= 0 else 'NOT FOUND'}",
          ('...' + ' '.join(t[max(0, i - 40):i + 180].split())) if i >= 0 else '')
PYEOF
expect_status "scan Command page" 0 $?
cat "$WORK/command.txt"
expect_content "Command exposes render_long_help" "$WORK/command.txt" "'render_long_help': FOUND"
expect_content "Command exposes get_subcommands"  "$WORK/command.txt" "'get_subcommands': FOUND"
expect_content "Command exposes term_width"       "$WORK/command.txt" "'term_width': FOUND"

hdr 9b "is a volatile version string actually present in clap --help output?"
echo "-- raw/opus.md recommends insta's \`filters\` feature because \"Rust --help output for this template will"
echo "-- contain the crate version in the -V, --version line\". This check tests that premise."
python3 - "$WORK/command.html" > "$WORK/help_template.txt" <<'PYEOF'
import re, html, sys
t = open(sys.argv[1], errors='replace').read()
t = re.sub('<[^>]+>', '', t); t = html.unescape(t); t = ' '.join(t.split())
i = t.find('Sets the help template to be used')
print("  docs.rs clap Command::help_template, retrieved from the page fetched in check 9")
print("  quoted:", ' '.join(t[i:i + 260].split()) if i >= 0 else 'NOT FOUND')
print(f"  {{version}} tag listed: {'{version}' in t[i:i+600] if i >= 0 else False}")
print("  the page does NOT quote the default template text, so what a default --help contains is not")
print("  established here; {version} is a tag a template must opt into, and the doc example that shows")
print("  it is labelled 'For showing more application context', i.e. an override of the default.")
DEFAULT_TEMPLATE_QUOTED = re.search(r'default template is[^.]*\{', t) is not None
print(f"  page quotes the default template: {DEFAULT_TEMPLATE_QUOTED}")
PYEOF
expect_status "scan Command::help_template prose" 0 $?
cat "$WORK/help_template.txt"
expect_content "help_template is documented as an override" "$WORK/help_template.txt" 'overriding the default format'
expect_content "{version} is an opt-in template tag"        "$WORK/help_template.txt" '\{version\} tag listed: True'
expect_content "the default template text is not quoted"    "$WORK/help_template.txt" 'page quotes the default template: False'

hdr 10 "py at the pin — the two source suites the ledger cites"
git -C "$PY" show "$PYPIN:tests/core/test_properties.py" > "$WORK/py-properties.py" 2>&1
expect_status "git show py tests/core/test_properties.py" 0 $?
sed -n '1,30p' "$WORK/py-properties.py"
echo "--- line 24 (F122 evidence):"
sed -n '24p' "$WORK/py-properties.py" | tee "$WORK/py-line24.txt"
expect_content "py line 24 is the Hypothesis @given line" "$WORK/py-line24.txt" '@given'
git -C "$PY" show "$PYPIN:tests/cli/test_help_snapshots.py" > "$WORK/py-help.py" 2>&1
expect_status "git show py tests/cli/test_help_snapshots.py" 0 $?
echo "--- line 36 (F123 evidence):"
sed -n '36p' "$WORK/py-help.py" | tee "$WORK/py-line36.txt"
expect_content "py line 36 is the syrupy snapshot assertion" "$WORK/py-line36.txt" 'assert result\.output == snapshot'
echo "--- committed syrupy snapshot fixture:"
git -C "$PY" ls-tree -r --name-only "$PYPIN" > "$WORK/py-tree.txt" 2>&1
expect_status "git ls-tree py at the pin" 0 $?
grep -i "snapshot\|ambr" "$WORK/py-tree.txt" | head | tee "$WORK/py-snapfiles.txt"
expect_content "the .ambr fixture is committed" "$WORK/py-snapfiles.txt" 'tests/cli/__snapshots__/test_help_snapshots\.ambr'
echo "--- pytest addopts and marker check (are either suite excluded by default?):"
git -C "$PY" show "$PYPIN:pyproject.toml" > "$WORK/py-pyproject.toml" 2>&1
expect_status "git show py pyproject.toml" 0 $?
grep -n "addopts" "$WORK/py-pyproject.toml" | head -3 | tee "$WORK/py-addopts.txt"
expect_content "addopts excludes only live and slow" "$WORK/py-addopts.txt" "not live and not slow"
n_prop=$(grep -c "pytest.mark.slow\|pytest.mark.live" "$WORK/py-properties.py"); echo "$n_prop"
n_help=$(grep -c "pytest.mark.slow\|pytest.mark.live" "$WORK/py-help.py"); echo "$n_help"
echo "(counts above are occurrences of slow/live markers in each file; 0 means the suite runs by default)"
expect_status "property suite carries no slow/live marker" 0 "$n_prop"
expect_status "help-snapshot suite carries no slow/live marker" 0 "$n_help"
echo "--- snapshot-update instruction in the py test file:"
grep -n "snapshot-update" "$WORK/py-help.py" | head -3 | tee "$WORK/py-update.txt"
expect_content "the regeneration command is in the docstring" "$WORK/py-update.txt" 'pytest tests/cli/test_help_snapshots\.py --snapshot-update'

hdr 11 "ts at the pin — is the absence of both capabilities drift or a language limit?"
echo "--- vitest and fast-check in package.json:"
git -C "$TS" show "$TSPIN:package.json" > "$WORK/ts-package.json" 2>&1
expect_status "git show ts package.json" 0 $?
grep -n "vitest\|fast-check" "$WORK/ts-package.json"; expect_status "grep vitest in package.json" 0 $?
expect_content "vitest 4.1.10 is a devDependency" "$WORK/ts-package.json" '"vitest": "\^4\.1\.10"'
expect_absent  "fast-check is absent"             "$WORK/ts-package.json" 'fast-check'
echo "--- does the pinned lockfile resolve a snapshot facility inside vitest itself?"
git -C "$TS" show "$TSPIN:pnpm-lock.yaml" > "$WORK/ts-lock.yaml" 2>&1
expect_status "git show ts pnpm-lock.yaml" 0 $?
grep -n "@vitest/snapshot" "$WORK/ts-lock.yaml" | head -5; expect_status "grep @vitest/snapshot" 0 $?
expect_content "the lockfile resolves @vitest/snapshot 4.1.10" "$WORK/ts-lock.yaml" "@vitest/snapshot.: 4\.1\.10|'@vitest/snapshot@4\.1\.10'"
echo "--- any snapshot or property test in the ts tree:"
git -C "$TS" grep -l -E "toMatchSnapshot|toMatchInlineSnapshot|fast-check|fc\.assert" "$TSPIN" > "$WORK/ts-usage.txt" 2>&1; st=$?
cat "$WORK/ts-usage.txt"
echo "git grep exit=$st (1 = no files match)"
expect_status "no file in the ts tree uses either capability" 1 "$st"
echo "--- does docs/port/TS_PORT_DECISIONS.md record a reason for either omission?"
git -C "$TS" show "$TSPIN:docs/port/TS_PORT_DECISIONS.md" > "$WORK/ts-decisions.md" 2>&1; st=$?
expect_status "git show ts docs/port/TS_PORT_DECISIONS.md" 0 "$st"
expect_content "the file is the TS port decision log" "$WORK/ts-decisions.md" '^## D-019:'
grep -n -i -E "hypothesis|syrupy|snapshot|fast-check|property-based|property test" "$WORK/ts-decisions.md" | head; st=$?
echo "grep exit=$st (1 = no line mentions any of these)"
expect_status "no recorded reason for either omission" 1 "$st"

hdr 11b "the ts testing decision D-019 in full, to show what it does settle"
echo "-- check 11 establishes the silence; this check prints the decision that is silent,"
echo "-- so the claim 'D-019 settles the runner and is silent on both capabilities' is readable."
grep -n -A 16 "^## D-019:" "$WORK/ts-decisions.md" > "$WORK/ts-d019.txt"; expect_status "extract D-019" 0 $?
cat "$WORK/ts-d019.txt"
expect_content "D-019 settles the test runner"     "$WORK/ts-d019.txt" 'Vitest 4'
expect_content "D-019 settles coverage thresholds" "$WORK/ts-d019.txt" 'Coverage provider, thresholds'
expect_absent  "D-019 says nothing about snapshots or property testing" "$WORK/ts-d019.txt" 'snapshot|fast-check|property'

hdr 12 "ledger and divergence rows this decision settles"
echo "-- repository root resolved from this script's location: $(basename "$ROOT")"
grep -n "F122\|F123" "$ROOT/docs/port/COMMONALITY.md" > "$WORK/ledger.txt"; expect_status "grep F122/F123 in COMMONALITY.md" 0 $?
cat "$WORK/ledger.txt"
expect_content "F122 is py-only and DIVERGENT, item R33" "$WORK/ledger.txt" '\| F122 \|.*py-only \| DIVERGENT \| R33 \|'
expect_content "F123 is py-only and DIVERGENT, item R33" "$WORK/ledger.txt" '\| F123 \|.*py-only \| DIVERGENT \| R33 \|'
grep -n "R33 property-and-snapshot-testing" "$ROOT/docs/port/DIVERGENCE-ANALYSIS.md" > "$WORK/divergence.txt"; expect_status "grep R33 in DIVERGENCE-ANALYSIS.md" 0 $?
cat "$WORK/divergence.txt"
expect_content "the divergence row is cause class D, harmonize yes" "$WORK/divergence.txt" '\| D \|.*\| yes \|'

hdr 13 "insta's documented CI behaviour and review commands (acceptance criteria 6 and 7)"
for page in quickstart cli; do
  code=$(curl -s --max-time 40 -H "$UA" -o "$WORK/insta-$page.html" -w '%{http_code}' "https://insta.rs/docs/$page/")
  echo "  --- https://insta.rs/docs/$page/  (HTTP $code)"
  expect_status "insta.rs $page page is HTTP 200" 200 "$code"
done
python3 - "$WORK" > "$WORK/insta-doc.txt" <<'PYEOF'
import re, html, sys
work = sys.argv[1]
pats = {
    "quickstart": ['will not write new snapshot files', '.new extension', 'CI'],
    "cli": ['cargo insta review', 'unreferenced', 'reject', 'accept', 'pending-snapshots', '--check'],
}
for page, patterns in pats.items():
    t = open(f"{work}/insta-{page}.html", errors='replace').read()
    t = re.sub('<[^>]+>', '', t); t = html.unescape(t); t = ' '.join(t.split())
    print(f"  --- https://insta.rs/docs/{page}/")
    for pat in patterns:
        i = t.find(pat)
        print(f"    {pat!r}: {'FOUND' if i >= 0 else 'NOT FOUND'}",
              ' '.join(t[max(0, i - 200):i + 200].split()) if i >= 0 else '')
PYEOF
expect_status "scan the insta.rs pages" 0 $?
cat "$WORK/insta-doc.txt"
expect_content "CI suppresses new snapshot files"        "$WORK/insta-doc.txt" "'will not write new snapshot files': FOUND"
expect_content "INSTA_UPDATE auto is 'no' under CI"      "$WORK/insta-doc.txt" "no for CI environments"
expect_content "--unreferenced defaults to ignore"       "$WORK/insta-doc.txt" "The default is ignore"
expect_content "the review subcommands are documented"   "$WORK/insta-doc.txt" "'pending-snapshots': FOUND"
expect_absent  "'--check' is NOT documented on the CLI page" "$WORK/insta-doc.txt" "'--check': FOUND"

echo
echo "===== SUMMARY ====="
echo "failed assertions: $fail"
echo "===== END ====="
exit "$fail"
