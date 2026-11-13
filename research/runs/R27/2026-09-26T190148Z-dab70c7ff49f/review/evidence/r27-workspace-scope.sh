#!/usr/bin/env bash
# R27 synthesis check C2 — format scope (F100, F162), the `--all` disagreement, the
# scope hazard, and the recommended Justfile recipes executed through `just`.
# Workspace shape follows R11's carried parameter: a root package hosting a binary,
# plus core and web members. Toolchain: the recommended rust-toolchain.toml shape at
# channel "1.96" (installed offline with rustfmt and clippy). No network.
set -uo pipefail
BIN="${TMPDIR:-/tmp}/r27s/bin"
mkdir -p "$BIN"
ln -sf "$HOME/.local/share/mise/installs/just/1.51.0/just" "$BIN/just"
export PATH="$HOME/.cargo/bin:$BIN:/usr/bin:/bin"
export RUSTUP_AUTO_INSTALL=0 CARGO_NET_OFFLINE=true NO_COLOR=1
ROOT="${TMPDIR:-/tmp}/r27s/ws"
rm -rf "$ROOT" && mkdir -p "$ROOT"
W=$(cd "$ROOT" && pwd -P)
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
clean() { sed -e $'s/\x1b\\[[0-9;]*m//g' -e $'s/\x1b(B//g' -e "s|$W/||g" -e "s|$ROOT/||g"; }
h() { shasum -a 256 "$1" | cut -c1-16; }

# ---- the workspace -------------------------------------------------------------------
cd "$W" || exit 2
mkdir -p src tests examples crates/core/src crates/web/src
cat > Cargo.toml <<'EOF'
[workspace]
members = ["crates/core", "crates/web"]

[workspace.package]
edition = "2024"
rust-version = "1.96"

[package]
name = "app"
version = "0.1.0"
edition.workspace = true
rust-version.workspace = true

[dependencies]
app-core = { path = "crates/core" }
app-web = { path = "crates/web" }
EOF
for m in core web; do
  printf '[package]\nname = "app-%s"\nversion = "0.1.0"\nedition.workspace = true\nrust-version.workspace = true\n' "$m" > "crates/$m/Cargo.toml"
done
printf 'fn main() {\n    app_core::run();\n}\n' > src/main.rs
printf 'fn main() {\n    println!("cargo::rerun-if-changed=build.rs");\n}\n' > build.rs
printf '#[test]\nfn it() {\n    assert_eq!(1, 1);\n}\n' > tests/it.rs
printf 'fn main() {}\n' > examples/demo.rs
printf 'pub fn run() {}\n' > crates/core/src/lib.rs
printf 'pub fn serve() {}\n' > crates/web/src/lib.rs
cat > rustfmt.toml <<'EOF'
# Rust source formatting (R27). Every key is stable: no nightly toolchain is needed.
edition = "2024"        # bare rustfmt callers parse 2024 syntax; cargo fmt passes Cargo.toml's edition
style_edition = "2024"  # the 2024 style edition
max_width = 100         # F087: rustfmt's default width, stated
newline_style = "Unix"  # F089: LF bytes on every OS; "Auto" keeps whatever a file already has
reorder_imports = true  # F092: the formatter owns import order (rustfmt's default, stated)
EOF
echo "== rustfmt.toml sha256 $(shasum -a 256 rustfmt.toml | cut -c1-64)"
cat > rust-toolchain.toml <<'EOF'
[toolchain]
channel = "1.96"
profile = "minimal"
components = ["rustfmt", "clippy"]
EOF
cat > Justfile <<'EOF'
# Format every Rust source file in the workspace in place
format:
    cargo fmt --all

# Check formatting without writing; also fail on an ignored rustfmt.toml key or an unreached .rs file
format-check:
    #!/usr/bin/env bash
    set -euo pipefail
    rc=0
    out=$(cargo fmt --all -- --check --verbose 2>&1) || rc=$?
    grep -v -e '^Formatting ' -e '^Using rustfmt config file ' -e '^Spent ' <<<"$out" || true
    if [ "$rc" -ne 0 ]; then exit "$rc"; fi
    if grep -q "can't set" <<<"$out"; then
        echo "error: rustfmt.toml sets a key this toolchain ignores" >&2
        exit 1
    fi
    root=$(pwd -P)
    unreached=$(comm -23 <(git ls-files -- '*.rs' | sort) <(sed -n "s|^Formatting $root/||p" <<<"$out" | sort -u))
    if [ -n "$unreached" ]; then
        printf 'error: tracked .rs files that cargo fmt does not reach:\n%s\n' "$unreached" >&2
        exit 1
    fi
EOF
git init -q . && git add -A && git -c user.name=r27 -c user.email=r27@example.invalid commit -qm base
echo "== toolchain: $(rustup show active-toolchain 2>&1 | clean)"
echo "== rustfmt:   $(cargo fmt --version)"
echo "== just:      $(just --version)"

echo
echo "== C2.1 baseline: formatted tree, bin + lib members + tests/ + examples/ + build.rs all tracked"
out=$(just format-check 2>&1); rc=$?
if [ "$rc" -eq 0 ]; then ok "just format-check exit=0 (both guards pass; tests/, examples/, build.rs reached)"; else bad "baseline exit=$rc"; echo "$out" | clean | sed 's/^/    | /'; fi
visited=$(cargo fmt --all -- --check --verbose 2>/dev/null | sed -n "s|^Formatting $W/||p" | sort -u | tr '\n' ' ')
echo "    reached: $visited"
echo "    tracked: $(git ls-files -- '*.rs' | sort | tr '\n' ' ')"

echo
echo "== C2.2 \`cargo fmt --check\` vs \`cargo fmt --all --check\` (Muse vs Opus): unformatted file in crates/web"
printf 'pub fn serve( ) {}\n' > crates/web/src/lib.rs
( cargo fmt --check >/dev/null 2>&1 ); r1=$?
( cargo fmt --all --check >/dev/null 2>&1 ); r2=$?
( cd crates/core && cargo fmt --check >/dev/null 2>&1 ); r3=$?
( cd crates/core && cargo fmt --all --check >/dev/null 2>&1 ); r4=$?
echo "    from root:        cargo fmt --check exit=$r1; cargo fmt --all --check exit=$r2"
echo "    from crates/core: cargo fmt --check exit=$r3; cargo fmt --all --check exit=$r4"
if [ "$r1" -eq 1 ] && [ "$r2" -eq 1 ]; then ok "at the workspace root both forms see the web member"; else bad "root r1=$r1 r2=$r2"; fi
if [ "$r3" -eq 0 ] && [ "$r4" -eq 1 ]; then ok "from a member directory only --all sees the web member (the plain form passes a dirty tree)"; else bad "subdir r3=$r3 r4=$r4"; fi
git checkout -q -- crates/web/src/lib.rs

echo
echo "== C2.3 structural exclusion works, and the reachability guard surfaces it"
mkdir -p vendor/legacy/src
printf '[package]\nname = "legacy"\nversion = "0.1.0"\nedition = "2021"\n' > vendor/legacy/Cargo.toml
printf 'pub fn legacy( ) {}\n' > vendor/legacy/src/lib.rs
awk '{print} /^members = /{print "exclude = [\"vendor/legacy\"]"}' Cargo.toml > Cargo.toml.new && mv Cargo.toml.new Cargo.toml
git add -A
grep -n '^exclude' Cargo.toml | sed 's/^/    Cargo.toml:/'
before=$(h vendor/legacy/src/lib.rs)
cargo fmt --all >/dev/null 2>&1
after=$(h vendor/legacy/src/lib.rs)
if [ "$before" = "$after" ]; then ok "[workspace] exclude: vendor/legacy/src/lib.rs untouched by cargo fmt --all ($before)"; else bad "vendor rewritten"; fi
out=$(just format-check 2>&1); rc=$?
if [ "$rc" -ne 0 ] && grep -q '^vendor/legacy/src/lib.rs$' <<<"$out"; then ok "guard names the excluded tracked file, exit=$rc (an exclusion cannot be silent)"; else bad "guard rc=$rc"; echo "$out" | clean | sed 's/^/    | /'; fi
git reset -q --hard && git clean -qfd

echo
echo "== C2.4 #[rustfmt::skip] on a mod declaration skips the whole file; the guard surfaces it"
printf 'pub fn g( ) {}\n' > crates/core/src/generated.rs
printf '#[rustfmt::skip]\nmod generated;\n\npub fn run() {}\n' > crates/core/src/lib.rs
git add -A
before=$(h crates/core/src/generated.rs)
( cargo fmt --all --check >/dev/null 2>&1 ); rc=$?
cargo fmt --all >/dev/null 2>&1
after=$(h crates/core/src/generated.rs)
if [ "$rc" -eq 0 ] && [ "$before" = "$after" ]; then ok "check exit=0 and generated.rs untouched by a write run"; else bad "skip rc=$rc"; fi
out=$(just format-check 2>&1); rc=$?
if [ "$rc" -ne 0 ] && grep -q '^crates/core/src/generated.rs$' <<<"$out"; then ok "guard names generated.rs, exit=$rc"; else bad "guard rc=$rc"; fi
git reset -q --hard

echo
echo "== C2.5 the scope hazard (Opus): an orphan file and a module declared inside a macro"
printf 'pub fn o( ) {}\n' > crates/core/src/orphan.rs
printf 'pub fn h( ) {}\n' > crates/core/src/hidden.rs
cat > crates/core/src/lib.rs <<'EOF'
macro_rules! decl {
    ($m:ident) => {
        pub mod $m;
    };
}
decl!(hidden);

pub fn run() {}
EOF
git add -A
( cargo fmt --all --check >/dev/null 2>&1 ); rc=$?
if [ "$rc" -eq 0 ]; then ok "cargo fmt --all --check exit=0 while orphan.rs and hidden.rs are unformatted (hazard reproduced)"; else bad "hazard rc=$rc"; fi
( cargo check -q -p app-core >/dev/null 2>&1 ); crc=$?
echo "    cargo check -p app-core exit=$crc (hidden.rs is compiled through the macro)"
out=$(just format-check 2>&1); rc=$?
if [ "$rc" -ne 0 ] && grep -q '^crates/core/src/hidden.rs$' <<<"$out" && grep -q '^crates/core/src/orphan.rs$' <<<"$out"; then ok "guard names both files, exit=$rc"; else bad "guard rc=$rc"; echo "$out" | clean | sed 's/^/    | /'; fi
echo "$out" | clean | sed 's/^/    | /'
git reset -q --hard && git clean -qfd

echo
echo "== C2.6 the unstable-key guard (Opus A2): an ignored key does not change cargo fmt's exit status"
printf 'imports_granularity = "Crate"\n' >> rustfmt.toml
( cargo fmt --all --check >/dev/null 2>&1 ); rc=$?
if [ "$rc" -eq 0 ]; then ok "cargo fmt --all --check exit=0 with imports_granularity set"; else bad "rc=$rc"; fi
out=$(just format-check 2>&1); rc=$?
if [ "$rc" -ne 0 ] && grep -q "sets a key this toolchain ignores" <<<"$out"; then ok "just format-check exit=$rc: guard fires"; else bad "guard rc=$rc"; fi
echo "$out" | clean | sed 's/^/    | /'
git checkout -q -- rustfmt.toml

echo
echo "== C2.7 the recipe's verdict: unformatted member file fails, format repairs, check passes"
printf 'pub fn serve( ) {}\n' > crates/web/src/lib.rs
out=$(just format-check 2>&1); rc=$?
if [ "$rc" -eq 1 ] && grep -q 'Diff in' <<<"$out"; then ok "format-check exit=1 and prints the diff"; else bad "rc=$rc"; fi
just format >/dev/null 2>&1
out=$(just format-check 2>&1); rc=$?
if [ "$rc" -eq 0 ]; then ok "after just format: format-check exit=0"; else bad "rc=$rc"; fi
git checkout -q -- crates/web/src/lib.rs

echo
echo "== C2.8 cost: /usr/bin/time -p cargo fmt --all --check, three consecutive runs on this workspace"
for i in 1 2 3; do
  t=$(/usr/bin/time -p sh -c 'cargo fmt --all --check >/dev/null 2>&1' 2>&1 | awk '/^real/{print $2}')
  echo "    run $i real=${t}s"
done
t=$(/usr/bin/time -p sh -c 'just format-check >/dev/null 2>&1' 2>&1 | awk '/^real/{print $2}')
echo "    just format-check real=${t}s"
if [ -n "$t" ] && awk -v t="$t" 'BEGIN{exit !(t < 5)}'; then ok "format-check measured at ${t}s, under 5 s on this host"; else bad "timing missing or slow: '$t'"; fi

echo
echo "== summary: $((PASS + FAIL)) checks, $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
