#!/usr/bin/env bash
# R33 property-and-snapshot-testing — synthesizer empirical check.
# Verifies claims made by raw/codex.md and raw/opus.md. Implements nothing.
set -u
UA='User-Agent: rs-launch-blueprint-research (steve@conceptm.com)'
PY=~/c/py-launch-blueprint
TS=~/c/ts-launch-blueprint
PYPIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TSPIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00

hdr() { echo; echo "===== CHECK $1 — $2 ====="; echo "-- run at $(date -u +%Y-%m-%dT%H:%M:%SZ)"; }

hdr 1 "toolchain and host"
rustc --version; echo "rustc exit=$?"
cargo --version; echo "cargo exit=$?"
echo "os: macOS $(sw_vers -productVersion) $(uname -m)"
echo "note: the template does not exist yet; no Rust workspace is built or resolved here."

hdr 2 "current stable Rust (msrv floor input)"
curl -s --max-time 30 https://static.rust-lang.org/dist/channel-rust-stable.toml | grep -m1 -A2 '^\[pkg.rust\]'
echo "curl exit=$?"

hdr 3 "crates.io — newest unyanked version, licence, rust_version, edition"
for c in proptest quickcheck insta cargo-insta snapbox expect-test proptest-derive; do
  code=$(curl -s --max-time 30 -H "$UA" -o "/tmp/r33-$c-versions.json" -w '%{http_code}' "https://crates.io/api/v1/crates/$c/versions")
  echo "GET https://crates.io/api/v1/crates/$c/versions -> HTTP $code"
  python3 - "$c" <<'PYEOF'
import json,sys
c=sys.argv[1]
d=json.load(open(f"/tmp/r33-{c}-versions.json"))
v=[x for x in d["versions"] if not x["yanked"]][0]
print(f"  {c}: num={v['num']} created_at={v['created_at']} license={v['license']!r} rust_version={v.get('rust_version')!r} edition={v.get('edition')!r}")
PYEOF
done

hdr 4 "crates.io — download and reverse-dependency figures"
for c in proptest quickcheck insta cargo-insta snapbox expect-test; do
  curl -s --max-time 30 -H "$UA" -o "/tmp/r33-$c.json" "https://crates.io/api/v1/crates/$c"
  curl -s --max-time 30 -H "$UA" -o "/tmp/r33-$c-rd.json" "https://crates.io/api/v1/crates/$c/reverse_dependencies?per_page=1"
  python3 - "$c" <<'PYEOF'
import json,sys
c=sys.argv[1]
d=json.load(open(f"/tmp/r33-{c}.json"))["crate"]
try: rd=json.load(open(f"/tmp/r33-{c}-rd.json"))["meta"]["total"]
except Exception as e: rd=f"unavailable ({e})"
print(f"  {c}: recent_downloads={d['recent_downloads']} downloads={d['downloads']} reverse_deps={rd}")
PYEOF
done

hdr 5 "RustSec package pages, with two known-advisory controls"
for c in proptest quickcheck insta cargo-insta snapbox expect-test proptest-derive time atty; do
  printf '  %-16s ' "$c"
  curl -s -o /dev/null --max-time 30 -w '%{http_code}\n' "https://rustsec.org/packages/$c.html"
done
echo "  controls 'time' and 'atty' are crates with published advisories; a 200 there with 404 elsewhere"
echo "  shows rustsec.org publishes a package page only when an advisory exists."

hdr 6 "first-party CI OS matrices (fitness gate 4)"
for spec in "proptest-rs/proptest .github/workflows/rust.yml" "mitsuhiko/insta .github/workflows/tests.yml" "assert-rs/snapbox .github/workflows/ci.yml"; do
  set -- $spec
  echo "--- $1 $2"
  gh api "repos/$1/contents/$2" --jq '.content' 2>/dev/null | base64 -d > "/tmp/r33-wf.yml"
  echo "gh exit=$?"
  grep -n -i "runs-on\|os:\|macos\|ubuntu\|windows" /tmp/r33-wf.yml | head -20
done

hdr 7 "insta manifest — licence field and default features (docs.rs correction)"
curl -s --max-time 30 https://raw.githubusercontent.com/mitsuhiko/insta/master/insta/Cargo.toml -o /tmp/r33-insta-manifest.toml
echo "curl exit=$?"
sed -n '1,45p' /tmp/r33-insta-manifest.toml
echo "--- workspace manifest: members and prebuilt targets"
curl -s --max-time 30 https://raw.githubusercontent.com/mitsuhiko/insta/master/Cargo.toml | sed -n '1,40p'

hdr 8 "proptest manifest at HEAD — rust-version vs the published 1.11.0 value"
curl -s --max-time 30 https://raw.githubusercontent.com/proptest-rs/proptest/master/proptest/Cargo.toml | grep -n -E "^(name|version|edition|rust-version|license)|^\[features\]|^default =" | head -20
echo "curl exit=$?"

hdr 9 "clap documentation — the determinism pins the B2 architecture depends on"
curl -s --max-time 40 -H "$UA" https://docs.rs/clap/latest/clap/builder/struct.StyledStr.html -o /tmp/r33-styledstr.html -w 'StyledStr HTTP %{http_code}\n'
python3 - <<'PYEOF'
import re,html
t=open('/tmp/r33-styledstr.html',errors='replace').read()
t=re.sub('<[^>]+>','',t); t=html.unescape(t)
for pat in ['Color-unaware printing','Never uses coloring','ansi(']:
    i=t.find(pat)
    print(f"  {pat!r}: {'FOUND' if i>=0 else 'NOT FOUND'}", ('...'+ ' '.join(t[max(0,i-120):i+120].split())) if i>=0 else '')
PYEOF
curl -s --max-time 40 -H "$UA" https://docs.rs/clap/latest/clap/struct.Command.html -o /tmp/r33-command.html -w 'Command HTTP %{http_code}\n'
python3 - <<'PYEOF'
import re,html
t=open('/tmp/r33-command.html',errors='replace').read()
t=re.sub('<[^>]+>','',t); t=html.unescape(t)
for pat in ['render_long_help','get_subcommands','term_width']:
    i=t.find(pat)
    print(f"  {pat!r}: {'FOUND' if i>=0 else 'NOT FOUND'}", ('...'+ ' '.join(t[max(0,i-40):i+180].split())) if i>=0 else '')
PYEOF

hdr 10 "py at the pin — the two source suites the ledger cites"
git -C "$PY" show "$PYPIN:tests/core/test_properties.py" | sed -n '1,30p'
echo "--- line 24 (F122 evidence):"
git -C "$PY" show "$PYPIN:tests/core/test_properties.py" | sed -n '24p'
echo "--- line 36 (F123 evidence):"
git -C "$PY" show "$PYPIN:tests/cli/test_help_snapshots.py" | sed -n '36p'
echo "--- committed syrupy snapshot fixture:"
git -C "$PY" ls-tree -r --name-only "$PYPIN" | grep -i "snapshot\|ambr" | head
echo "--- pytest addopts and marker check (are either suite excluded by default?):"
git -C "$PY" show "$PYPIN:pyproject.toml" | grep -n "addopts" | head -3
git -C "$PY" show "$PYPIN:tests/core/test_properties.py" | grep -c "pytest.mark.slow\|pytest.mark.live"
git -C "$PY" show "$PYPIN:tests/cli/test_help_snapshots.py" | grep -c "pytest.mark.slow\|pytest.mark.live"
echo "(counts above are occurrences of slow/live markers in each file; 0 means the suite runs by default)"
echo "--- snapshot-update instruction in the py test file:"
git -C "$PY" show "$PYPIN:tests/cli/test_help_snapshots.py" | grep -n "snapshot-update" | head -3

hdr 11 "ts at the pin — is the absence of both capabilities drift or a language limit?"
echo "--- vitest and fast-check in package.json:"
git -C "$TS" show "$TSPIN:package.json" | grep -n "vitest\|fast-check"
echo "--- does the pinned lockfile resolve a snapshot facility inside vitest itself?"
git -C "$TS" show "$TSPIN:pnpm-lock.yaml" | grep -n "@vitest/snapshot" | head -5
echo "--- any snapshot or property test in the ts tree:"
git -C "$TS" grep -l -E "toMatchSnapshot|toMatchInlineSnapshot|fast-check|fc\.assert" "$TSPIN"
echo "grep exit=$? (1 = no files match)"
echo "--- does TS_PORT_DECISIONS.md record a reason for either omission?"
git -C "$TS" show "$TSPIN:TS_PORT_DECISIONS.md" | grep -n -i -E "hypothesis|syrupy|snapshot|fast-check|property-based|property test" | head
echo "grep exit=$? (1 = no line mentions any of these)"

hdr 12 "ledger and divergence rows this decision settles"
grep -n "F122\|F123" docs/port/COMMONALITY.md
grep -n "R33 property-and-snapshot-testing" docs/port/DIVERGENCE-ANALYSIS.md

echo
echo "===== END ====="
