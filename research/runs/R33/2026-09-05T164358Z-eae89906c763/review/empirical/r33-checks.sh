#!/usr/bin/env bash
# R33 property-and-snapshot-testing — synthesizer empirical check (revision 3).
# Verifies claims made by raw/codex.md and raw/opus.md. Implements nothing:
# no crate is scaffolded, no tool installed, no workspace or lockfile created.
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
