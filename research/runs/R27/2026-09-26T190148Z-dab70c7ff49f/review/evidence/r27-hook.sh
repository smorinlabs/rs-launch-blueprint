#!/usr/bin/env bash
# R27 synthesis check C3 — the pre-commit formatter job (F104), through real `git commit`
# with lefthook-installed hooks. Variant A is the recommended job (check-and-block, no glob);
# variant B is the Opus leg's job (same, plus glob "*.rs"); variant C is the ts shape
# (write mode + stage_fixed). Also reproduces why `cargo fmt` cannot be scoped to staged files.
# Toolchain: the recommended rust-toolchain.toml shape at channel "1.96". No network.
set -uo pipefail
BIN="${TMPDIR:-/tmp}/r27s/bin"
mkdir -p "$BIN"
ln -sf /opt/homebrew/bin/lefthook "$BIN/lefthook"
export PATH="$HOME/.cargo/bin:$BIN:/usr/bin:/bin"
export RUSTUP_AUTO_INSTALL=0 NO_COLOR=1
BASE="$(cd "${TMPDIR:-/tmp}/r27s" && pwd -P)/hook"
rm -rf "$BASE" && mkdir -p "$BASE"
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
h() { shasum -a 256 "$1" | cut -c1-16; }
G() { git -c user.name=r27 -c user.email=r27@example.invalid "$@"; }
commits() { git rev-list --count HEAD; }

JOB_A='pre-commit:
  jobs:
    - name: rustfmt
      run: cargo fmt --all --check
'
JOB_B='pre-commit:
  jobs:
    - name: rustfmt
      glob: "*.rs"
      run: cargo fmt --all --check
'
JOB_C='pre-commit:
  jobs:
    - name: rustfmt
      run: cargo fmt --all
      stage_fixed: true
'

# repo <name> <lefthook.yml text>: fresh formatted crate with hooks installed; cd into it
repo() {
  local d="$BASE/$1"
  mkdir -p "$d/src" && cd "$d" || exit 2
  git init -q .
  printf '[package]\nname = "p"\nversion = "0.1.0"\nedition = "2024"\n' > Cargo.toml
  printf '[toolchain]\nchannel = "1.96"\nprofile = "minimal"\ncomponents = ["rustfmt", "clippy"]\n' > rust-toolchain.toml
  printf 'edition = "2024"\nstyle_edition = "2024"\nmax_width = 100\nnewline_style = "Unix"\nreorder_imports = true\n' > rustfmt.toml
  printf 'mod web;\n\npub fn run() {}\n' > src/lib.rs
  printf 'pub fn serve(address: &str, port: u16, verbose: bool) -> bool {\n    verbose && port > 0 && !address.is_empty()\n}\n' > src/web.rs
  printf '# p\n' > README.md
  printf '%s' "$2" > lefthook.yml
  G add -A && G commit -qm base
  lefthook install >/dev/null 2>&1 || { echo "lefthook install failed"; exit 2; }
}

echo "== lefthook $(lefthook version); $(git --version); toolchain via rust-toolchain.toml: $(cd "$BASE" && printf '[toolchain]\nchannel = "1.96"\n' > rust-toolchain.toml && cargo fmt --version && rm rust-toolchain.toml)"

for V in A B; do
  if [ "$V" = A ]; then JOB="$JOB_A"; else JOB="$JOB_B"; fi
  echo
  echo "== variant $V: $(tr '\n' ' ' <<<"$JOB" | sed 's/  */ /g')"

  repo "$V-h1" "$JOB"
  printf 'mod web;\n\npub fn run( ) {}\n' > src/lib.rs; G add src/lib.rs
  before=$(h src/lib.rs); n0=$(commits)
  out=$(G commit -m h1 2>&1); rc=$?
  if [ "$rc" -ne 0 ] && [ "$(commits)" = "$n0" ] && [ "$before" = "$(h src/lib.rs)" ]; then ok "$V H1 staged unformatted .rs: commit rejected (exit=$rc), file bytes unchanged"; else bad "$V H1 rc=$rc"; fi

  repo "$V-h2" "$JOB"
  printf 'mod web;\n\npub fn run() {}\n\npub fn two() {}\n' > src/lib.rs; G add src/lib.rs
  out=$(G commit -m h2 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then ok "$V H2 staged formatted .rs: commit accepted"; else bad "$V H2 rc=$rc"; fi

  repo "$V-h3" "$JOB"
  printf '# p\n\nmore\n' > README.md; G add README.md
  out=$(G commit -m h3 2>&1); rc=$?
  if grep -q "no matching staged files" <<<"$out"; then ran="skipped"; else ran="ran"; fi
  if [ "$rc" -eq 0 ]; then ok "$V H3 README-only commit accepted; formatter job $ran"; else bad "$V H3 rc=$rc"; fi

  repo "$V-h4" "$JOB"
  printf 'edition = "2024"\nstyle_edition = "2024"\nmax_width = 40\nnewline_style = "Unix"\nreorder_imports = true\n' > rustfmt.toml; G add rustfmt.toml
  ( cargo fmt --all --check >/dev/null 2>&1 ); tree=$?
  n0=$(commits); out=$(G commit -m h4 2>&1); rc=$?
  echo "    H4 rustfmt.toml-only change to max_width = 40: the tree is now unformatted (cargo fmt --all --check exit=$tree)"
  if [ "$V" = A ]; then
    if [ "$rc" -ne 0 ] && [ "$(commits)" = "$n0" ]; then ok "A H4 config-only commit that unformats the tree: rejected (exit=$rc)"; else bad "A H4 rc=$rc"; fi
  else
    if [ "$rc" -eq 0 ] && grep -q "no matching staged files" <<<"$out"; then ok "B H4 config-only commit that unformats the tree: ACCEPTED, job skipped by glob (the discriminating case)"; else bad "B H4 rc=$rc"; fi
  fi
done

echo
echo "== variant A, working-tree interaction (lefthook hides the unstaged part of partially staged files only)"
repo "A-h5" "$JOB_A"
printf 'mod web;\n\npub fn run( ) {}\n' > src/lib.rs; G add src/lib.rs
printf 'mod web;\n\npub fn run() {}\n' > src/lib.rs
n0=$(commits); out=$(G commit -m h5 2>&1); rc=$?
if [ "$rc" -ne 0 ] && [ "$(commits)" = "$n0" ] && grep -q 'pub fn run() {}' src/lib.rs; then ok "A H5 index unformatted, working tree formatted (partially staged): rejected (exit=$rc); unstaged bytes restored"; else bad "A H5 rc=$rc"; fi

repo "A-h6" "$JOB_A"
printf 'mod web;\n\npub fn run() {}\n\npub fn two() {}\n' > src/lib.rs; G add src/lib.rs
printf 'pub fn serve( address: &str, port: u16, verbose: bool) -> bool { verbose && port > 1 && !address.is_empty() }\n' > src/web.rs
n0=$(commits); out=$(G commit -m h6 2>&1); rc=$?
if [ "$rc" -ne 0 ] && [ "$(commits)" = "$n0" ]; then ok "A H6 formatted staged change + unrelated UNSTAGED unformatted edit to web.rs: rejected (exit=$rc) — a conservative false block"; else bad "A H6 rc=$rc"; fi
grep -m1 "Diff in" <<<"$out" | sed -e "s|$BASE/||" -e 's/^/    | /'

echo
echo "== variant C (ts shape: write mode + stage_fixed): the same H6 situation"
repo "C-h6" "$JOB_C"
printf 'mod web;\n\npub fn run() {}\n\npub fn two() {}\n' > src/lib.rs; G add src/lib.rs
printf 'pub fn serve( address: &str, port: u16, verbose: bool) -> bool { verbose && port > 1 && !address.is_empty() }\n' > src/web.rs
before=$(h src/web.rs); n0=$(commits); out=$(G commit -m c6 2>&1); rc=$?
after=$(h src/web.rs)
in_commit=$(git show --name-only --format= HEAD | tr '\n' ' ')
echo "    commit exit=$rc; files in the new commit: $in_commit; web.rs working-tree sha $before -> $after; status: $(git status --short | tr '\n' ' ')"
if [ "$rc" -eq 0 ] && [ "$before" != "$after" ] && ! grep -q 'src/web.rs' <<<"$in_commit"; then ok "C H6 the hook rewrote web.rs, a file the contributor never staged, and left it out of the commit"; else bad "C H6 rc=$rc"; fi

echo
echo "== W: \`cargo fmt\` cannot be scoped to named files (why the ts write mode does not transfer under R42's invocation rule)"
repo "W" "$JOB_A"
printf 'mod web;\n\npub fn run( ) {}\n' > src/lib.rs
printf 'pub fn serve( address: &str, port: u16, verbose: bool) -> bool { verbose }\n' > src/web.rs
out=$(cargo fmt -- --check src/web.rs 2>&1); rc=$?
files=$(grep -o 'Diff in [^:]*' <<<"$out" | sed "s|Diff in $BASE/W/||;s|Diff in /private$BASE/W/||" | sort | uniq -c | tr '\n' ';')
echo "    cargo fmt -- --check src/web.rs: exit=$rc; diffs reported per file: $files"
if [ "$rc" -eq 1 ] && grep -q 'lib.rs' <<<"$files"; then ok "W1 naming one file still checks lib.rs"; else bad "W1"; fi
lb=$(h src/lib.rs); cargo fmt -- src/web.rs >/dev/null 2>&1; la=$(h src/lib.rs)
if [ "$lb" != "$la" ]; then ok "W2 write run naming only web.rs rewrote lib.rs too ($lb -> $la)"; else bad "W2 lib.rs untouched"; fi

echo
echo "== summary: $((PASS + FAIL)) checks, $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
