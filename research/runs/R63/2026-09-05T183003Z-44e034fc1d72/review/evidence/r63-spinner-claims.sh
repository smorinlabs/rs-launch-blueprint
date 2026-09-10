#!/bin/bash
# R63 progress-spinner — decision-audit empirical check.
# Verifies claims made in the raw reports. Implements nothing.
set -u
UA='rs-launch-blueprint-research/R63'
W=/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad/r63
TS=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PY=b08bccfb55d05f15e46a83b52c5660b1881d19f5
mkdir -p "$W/src" && cd "$W" || exit 1

hr(){ printf '\n===== %s =====\n' "$1"; }

hr "0. TOOLCHAIN AND HOST"
rustc --version; cargo --version
printf 'os: macOS %s (%s)\n' "$(sw_vers -productVersion)" "$(uname -m)"
printf 'date: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'current stable channel version: '
curl -sS -A "$UA" https://static.rust-lang.org/dist/channel-rust-stable.toml \
  | grep -m1 -A2 '^\[pkg.rust\]' | grep -m1 '^version'

hr "1. INHERITED CONTRACT AT THE ts PIN (gate predicate)"
echo "--- ts:src/commands/projects.ts lines 120-140 @ $TS"
git -C ~/c/ts-launch-blueprint show "$TS:src/commands/projects.ts" | sed -n '120,140p' | cat -n | sed 's/^/    /'
echo "--- ts:src/lib/adapters.ts lines 25-72 @ $TS (SpinnerFactory + D-033 guard)"
git -C ~/c/ts-launch-blueprint show "$TS:src/lib/adapters.ts" | sed -n '25,72p' | cat -n | sed 's/^/    /'
echo "--- ts:package.json spinner dependency @ $TS"
git -C ~/c/ts-launch-blueprint show "$TS:package.json" | grep -n -i 'spinner\|ora'
echo "--- ts:docs/port/TS_PORT_DECISIONS.md D-016(5) / D-033 lines @ $TS"
git -C ~/c/ts-launch-blueprint show "$TS:docs/port/TS_PORT_DECISIONS.md" | grep -n 'progress=diagnostics\|yocto-spinner\|0-column\|0 column' | head -20

hr "2. py PIN — IS THERE ANY PROGRESS INDICATOR?"
echo "--- git grep over *.py *.toml @ $PY"
git -C ~/c/py-launch-blueprint grep -il -e spinner -e tqdm -e progressbar -e 'rich.progress' -e 'Progress(' "$PY" -- '*.py' '*.toml'
echo "exit=$? (1 = no matches)"
echo "--- py:pyproject.toml rich dependency @ $PY"
git -C ~/c/py-launch-blueprint show "$PY:pyproject.toml" | grep -n -i 'rich'

hr "3. is_ci PREDICATE AT A PINNED VERSION"
curl -sS -A "$UA" https://crates.io/api/v1/crates/is_ci/versions \
  | python3 -c 'import json,sys; d=json.load(sys.stdin)["versions"]; v=[x for x in d if not x["yanked"]][0]; print("newest unyanked:", v["num"], v["created_at"], "license:", v["license"], "rust_version:", v["rust_version"])'
curl -sS -A "$UA" -o src/is_ci-1.2.0.crate https://static.crates.io/crates/is_ci/is_ci-1.2.0.crate
tar -xzf src/is_ci-1.2.0.crate -C src
echo "--- is_ci-1.2.0/src/lib.rs (published artifact, not a branch)"
cat -n src/is_ci-1.2.0/src/lib.rs

hr "4. indicatif 0.18.6 — PUBLISHED ARTIFACT (license, MSRV, edition, stderr default)"
curl -sS -A "$UA" -o src/indicatif-0.18.6.crate https://static.crates.io/crates/indicatif/indicatif-0.18.6.crate
tar -xzf src/indicatif-0.18.6.crate -C src
echo "--- indicatif-0.18.6/Cargo.toml [package] head"
sed -n '1,40p' src/indicatif-0.18.6/Cargo.toml
echo "--- default features"
grep -n -A6 '^\[features\]' src/indicatif-0.18.6/Cargo.toml | head -20
echo "--- optional async deps"
grep -n -B2 -A4 'tokio\|futures-core\|rayon' src/indicatif-0.18.6/Cargo.toml | head -40
echo "--- ProgressBar::new_spinner draw target"
grep -n -B6 -A8 'pub fn new_spinner' src/indicatif-0.18.6/src/progress_bar.rs
echo "--- ProgressDrawTarget::stderr / hidden / term"
grep -n -B8 -A10 'pub fn stderr()' src/indicatif-0.18.6/src/draw_target.rs
grep -n -B4 -A6 'pub fn hidden()' src/indicatif-0.18.6/src/draw_target.rs
grep -n -B6 -A8 'pub fn term(' src/indicatif-0.18.6/src/draw_target.rs
echo "--- in_memory feature / InMemoryTerm"
grep -n 'in_memory' src/indicatif-0.18.6/Cargo.toml
grep -n 'pub fn contents\|impl TermLike for InMemoryTerm\|pub struct InMemoryTerm' src/indicatif-0.18.6/src/in_memory.rs
echo "--- zero-width handling inside indicatif (codex claim: regression test at width 0)"
grep -rn 'draw_to_term_narrower_than_its_content' src/indicatif-0.18.6/src/ | head
grep -rn 'width == 0\|width() == 0\|\.max(1)' src/indicatif-0.18.6/src/*.rs | head -20
echo "--- unsafe count in indicatif src"
grep -rc 'unsafe' src/indicatif-0.18.6/src/*.rs | grep -v ':0$' || echo "no file contains 'unsafe'"

hr "5. console 0.16.6 — ZERO-COLUMN FALLBACK (source read, NOT an executed pty test)"
curl -sS -A "$UA" -o src/console-0.16.6.crate https://static.crates.io/crates/console/console-0.16.6.crate
tar -xzf src/console-0.16.6.crate -C src
grep -n 'DEFAULT_WIDTH' src/console-0.16.6/src/unix_term.rs | head
grep -n -B6 -A12 'fn terminal_size' src/console-0.16.6/src/unix_term.rs
grep -n -B4 -A8 'pub fn size(&self)' src/console-0.16.6/src/term.rs
grep -n 'rust-version\|^license\|^edition' src/console-0.16.6/Cargo.toml

hr "6. indicatif CI MATRIX AT TAG 0.18.6"
curl -sS -A "$UA" https://raw.githubusercontent.com/console-rs/indicatif/0.18.6/.github/workflows/rust.yml \
  | grep -n 'os:\|toolchain:\|rust:' | head -30

hr "7. REGISTRY FIGURES (crates.io), retrieved now"
for c in indicatif console spinners spinoff cliclack spinach throbber-widgets-tui is_ci ci_info prodash; do
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/$c" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin)["crate"]; print("%-22s recent_downloads=%-12s downloads=%-12s max_stable=%s" % (d["name"], d.get("recent_downloads"), d.get("downloads"), d.get("max_stable_version")))'
done
echo "--- newest unyanked version + rust_version per candidate"
for c in indicatif spinners spinoff cliclack spinach prodash; do
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/$c/versions" \
    | python3 -c "import json,sys; vs=[v for v in json.load(sys.stdin)['versions'] if not v['yanked']]; v=vs[0]; print('%-22s num=%-8s created_at=%-22s license=%-22s rust_version=%s' % ('$c', v['num'], v['created_at'], v['license'], v['rust_version']))"
done

hr "8. GITHUB REPO FIGURES + OPEN ISSUES (mandated total_count, not open_issues_count)"
for r in console-rs/indicatif fadeevab/cliclack FGRibreau/spinners ad4mx/spinoff GitoxideLabs/prodash zkat/is_ci; do
  gh api "repos/$r" --jq '"\(.full_name) stars=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at) open_issues_count(incl PRs)=\(.open_issues_count)"'
  sleep 2
done
gh api "search/issues?q=repo:console-rs/indicatif+is:issue+is:open" --jq '"console-rs/indicatif open issues (search total_count) = \(.total_count)"'

hr "9. RUSTSEC PAGES + 404-MEANS-CLEAN CONTROL"
for p in indicatif console unicode-width portable-atomic unit-prefix libc is_ci ci_info spinners spinoff cliclack; do
  printf '%-20s %s\n' "$p" "$(curl -sS -o /dev/null -w '%{http_code}' -A "$UA" "https://rustsec.org/packages/$p.html")"
done
echo "--- control: crates known to have advisories must return 200 with RUSTSEC- content"
for p in time openssl atty; do
  code=$(curl -sS -o "$W/rustsec-$p.html" -w '%{http_code}' -A "$UA" "https://rustsec.org/packages/$p.html")
  printf '%-20s %s  RUSTSEC- mentions=%s\n' "$p" "$code" "$(grep -c 'RUSTSEC-' "$W/rustsec-$p.html")"
done

hr "10. EXCLUDED-CANDIDATE CLAIMS AT PUBLISHED VERSIONS"
curl -sS -A "$UA" -o src/spinoff-0.8.0.crate https://static.crates.io/crates/spinoff/spinoff-0.8.0.crate
tar -xzf src/spinoff-0.8.0.crate -C src
echo "--- spinoff 0.8.0: default stream (opus claim: stdout)"
grep -n -B4 -A6 'stdout stream\|Stdout' src/spinoff-0.8.0/src/lib.rs | head -40
grep -n 'rust-version' src/spinoff-0.8.0/Cargo.toml || echo "spinoff 0.8.0 Cargo.toml: NO rust-version key"
curl -sS -A "$UA" -o src/spinners-4.2.0.crate https://static.crates.io/crates/spinners/spinners-4.2.0.crate
tar -xzf src/spinners-4.2.0.crate -C src
echo "--- spinners 4.2.0: EPIPE panic claim + default stream + rust-version"
grep -n 'expect("IO Error")' src/spinners-4.2.0/src/lib.rs
grep -rn 'default\]' src/spinners-4.2.0/src/utils/stream.rs | head
grep -n 'rust-version' src/spinners-4.2.0/Cargo.toml || echo "spinners 4.2.0 Cargo.toml: NO rust-version key"
grep -n 'lazy_static\|maplit\|strum' src/spinners-4.2.0/Cargo.toml
echo "--- cliclack: rust_version across recent versions + CI presence"
curl -sS -A "$UA" https://crates.io/api/v1/crates/cliclack/versions \
  | python3 -c 'import json,sys; [print(v["num"], "rust_version=", v["rust_version"], "license=", v["license"]) for v in json.load(sys.stdin)["versions"][:4]]'
gh api "repos/fadeevab/cliclack/contents" --jq '[.[].name] | join(", ")' 2>&1 | head -3
gh api "repos/fadeevab/cliclack/contents/.github/workflows" 2>&1 | head -3

hr "11. MSRV ARITHMETIC CHECK"
echo "policy floor = stable minus 2 minor versions; recommended tree maxima:"
for c in indicatif console unicode-width portable-atomic unit-prefix; do
  printf '%-18s ' "$c"
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/$c/versions" \
    | python3 -c "import json,sys; vs=[v for v in json.load(sys.stdin)['versions'] if not v['yanked']]; print('newest=%s rust_version=%s license=%s' % (vs[0]['num'], vs[0]['rust_version'], vs[0]['license']))"
done

hr "DONE"

# ---------------------------------------------------------------------------
# PART 2 — supplements 12-18, appended to the same log after reading part 1.
# These were run as follow-up commands once part 1's output showed which
# claims part 1 had not resolved. Reproduced here verbatim so the whole
# check is re-runnable. Each expects part 1's unpacked artifacts under ./src.
# ---------------------------------------------------------------------------
supplements() {
hr "12. SUPPLEMENT: CLAIMS NOT RESOLVED BY THE FIRST PASS"
grep -n -i 'stdout' src/spinoff-0.8.0/src/lib.rs | head -20
sed -n '1,30p' src/spinners-4.2.0/src/utils/stream.rs
grep -rn 'draw_to_term_narrower_than_its_content' src/indicatif-0.18.6/; echo "grep exit=$? (1 = absent from the published 0.18.6 artifact)"
find src/indicatif-0.18.6 -type f | sort
curl -sS -A "$UA" https://raw.githubusercontent.com/console-rs/indicatif/0.18.6/src/draw_target.rs > dt-tag.rs
grep -n 'draw_to_term_narrower_than_its_content' dt-tag.rs; echo "grep exit=$? (1 = absent at git tag 0.18.6)"
curl -sS -A "$UA" https://raw.githubusercontent.com/console-rs/indicatif/main/src/draw_target.rs > dt-main.rs
grep -n -A16 'fn draw_to_term_narrower_than_its_content' dt-main.rs
sed -n '53,80p' src/console-0.16.6/src/unix_term.rs

hr "13-15. SUPPLEMENT: THE WIDTH PATH AT 0.18.6"
grep -rn 'impl TermLike for Term\|fn width(&self)' src/indicatif-0.18.6/src/*.rs
sed -n '1,50p' src/indicatif-0.18.6/src/term_like.rs
grep -rn '/ width\|div_ceil' src/indicatif-0.18.6/src/*.rs
awk 'NR>=655 && NR<=720 {printf "%d\t%s\n", NR, $0}' src/indicatif-0.18.6/src/draw_target.rs

hr "16. SUPPLEMENT: DOES indicatif 0.18.6 READ ANY ENVIRONMENT VARIABLE?"
grep -rn 'env::var\|env!\|std::env' src/indicatif-0.18.6/src/; echo "grep exit=$? (1 = no env access)"
grep -rn '"CI"' src/indicatif-0.18.6/src/; echo "grep exit=$? (1 = indicatif never reads CI)"
grep -rn 'fn is_dumb\|"TERM"' src/console-0.16.6/src/*.rs src/indicatif-0.18.6/src/*.rs

hr "17. SUPPLEMENT: enable_steady_tick / finish_and_clear / is_hidden AT 0.18.6"
grep -n -B14 -A6 'pub fn enable_steady_tick' src/indicatif-0.18.6/src/progress_bar.rs
grep -n -B4 -A6 'pub fn finish_and_clear' src/indicatif-0.18.6/src/progress_bar.rs
grep -n -B3 -A6 'pub fn is_hidden' src/indicatif-0.18.6/src/progress_bar.rs

hr "18. SUPPLEMENT: THE TWO CANDIDATES ONLY THE CODEX RAW SURVEYED"
curl -sS -A "$UA" https://raw.githubusercontent.com/GitoxideLabs/prodash/main/Cargo.toml | grep -m1 'rust-version'
curl -sS -A "$UA" -o src/prodash-31.0.0.crate https://static.crates.io/crates/prodash/prodash-31.0.0.crate && tar -xzf src/prodash-31.0.0.crate -C src
grep -m1 'rust-version' src/prodash-31.0.0/Cargo.toml; grep -m1 '^license' src/prodash-31.0.0/Cargo.toml
curl -sS -A "$UA" https://raw.githubusercontent.com/GitoxideLabs/prodash/main/.github/workflows/ci.yml | grep -n -i 'runs-on\|os:\|macos\|ubuntu\|windows'
grep -n -A12 '^\[features\]' src/prodash-31.0.0/Cargo.toml | head -20
curl -sS -o /dev/null -w '%{http_code}\n' -A "$UA" https://rustsec.org/packages/prodash.html
curl -sS -A "$UA" https://crates.io/api/v1/crates/spinner/versions | python3 -c 'import json,sys; v=[x for x in json.load(sys.stdin)["versions"] if not x["yanked"]][0]; print("newest unyanked:", v["num"], v["created_at"], "license:", v["license"], "rust_version:", v["rust_version"])'
gh api repos/TheNeikos/spinner --jq '"TheNeikos/spinner archived=\(.archived) stars=\(.stargazers_count) pushed_at=\(.pushed_at)"'
}
# supplements   # uncomment to re-run part 2
