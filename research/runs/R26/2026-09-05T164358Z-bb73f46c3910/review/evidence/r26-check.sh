#!/usr/bin/env bash
# R26 packed-artifact-content-guard — synthesizer empirical check.
# Verifies claims only. Publishes nothing; never invokes `cargo publish`.
set -u

SCRATCH="/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad"
SHA=797e8a9bca276c1c9f9f738d2a20f484fa4eea9d
W="$SCRATCH/probe"
G="$SCRATCH/guardwork"   # guard scratch, deliberately OUTSIDE the probe git repo
PKG=rsguard
VER=0.1.0

hr() { printf '\n===== %s =====\n' "$1"; }

hr "PHASE 0 — toolchain and host"
cargo --version
rustc --version
uname -sm
sw_vers | tr '\n' ' '; echo
echo "cargo binary commit -> rust-lang/cargo pin:"
gh api "repos/rust-lang/cargo/commits/$SHA" -q '.sha + "  " + .commit.committer.date'

hr "PHASE 1 — pinned cargo source: target pruning is warn-only"
echo "# src/cargo/util/toml/mod.rs @ $SHA (prune helper)"
sed -n '3298,3316p' "$SCRATCH/toml_mod.rs"
echo "# call sites"
grep -n 'prepare_target\(s\)\?_for_publish(me\?\.\?[a-z]*\.\?a\?s\?_\?r\?e\?f\?' "$SCRATCH/toml_mod.rs" | sed -n '1,10p'
grep -n '"library"\|"binary"\|"example"\|"test"\|"benchmark"' "$SCRATCH/toml_mod.rs" | sed -n '1,12p'
echo "# src/cargo/ops/cargo_package/mod.rs @ $SHA (include+exclude)"
sed -n '482,488p' "$SCRATCH/pkg_mod.rs"
echo "# src/doc/src/CHANGELOG.md @ $SHA"
sed -n '2670p;2718,2719p' "$SCRATCH/book-CHANGELOG.md"
sed -n '518p;575,576p' "$SCRATCH/book-CHANGELOG.md"

hr "PHASE 2 — build throwaway probe crate (lib + 2 bins)"
rm -rf "$W" "$G"; mkdir -p "$W/src/bin" "$G"
cat > "$W/Cargo.toml" <<'EOF'
[package]
name = "rsguard"
version = "0.1.0"
edition = "2024"
license = "MIT OR Apache-2.0"
description = "R26 probe"
include = ["src/**/*.rs", "Cargo.toml", "README.md"]
EOF
echo 'pub fn v() -> u8 { 1 }' > "$W/src/lib.rs"
echo 'fn main() { println!("cli"); }' > "$W/src/main.rs"
echo 'fn main() { println!("serve"); }' > "$W/src/bin/rsguard-serve.rs"
echo '# probe' > "$W/README.md"
echo 'stray' > "$W/STRAY.txt"
cd "$W" || exit 1
git init -q . && git add -A && git -c user.email=r26@probe -c user.name=r26 commit -qm init
cargo generate-lockfile --offline >/dev/null 2>&1
git add -A && git -c user.email=r26@probe -c user.name=r26 commit -qm lock
ls -1

hr "PHASE 3 — expectation files (the only fixtures this check needs)"
cat > "$G/expected-packed-files.txt" <<'EOF'
.cargo_vcs_info.json
Cargo.lock
Cargo.toml
Cargo.toml.orig
README.md
src/bin/rsguard-serve.rs
src/lib.rs
src/main.rs
EOF
cat > "$G/expected-packaged-targets.json" <<'EOF'
[{"kind":["bin"],"name":"rsguard"},{"kind":["bin"],"name":"rsguard-serve"},{"kind":["lib"],"name":"rsguard"}]
EOF
cat "$G/expected-packed-files.txt"; cat "$G/expected-packaged-targets.json"

guard() {
  local label="$1" rc=0
  hr "GUARD RUN — $label"
  rm -rf "$G/x"; mkdir -p "$G/x"
  echo "--- sub-check 1: cargo package --list vs expectation"
  cargo package -p "$PKG" --list --no-verify --offline --locked > "$G/files.txt" 2> "$G/list.err"
  echo "cargo package --list exit=$?"
  cat "$G/list.err"
  diff -u "$G/expected-packed-files.txt" "$G/files.txt" || rc=1
  echo "sub-check 1 rc=$rc"

  echo "--- sub-check 2: cargo package stderr (scoped grep)"
  cargo package -p "$PKG" --no-verify --offline --locked > "$G/pack.out" 2> "$G/pack.err"
  local pack_rc=$?
  echo "cargo package exit=$pack_rc"
  cat "$G/pack.err"
  if grep -Eq 'ignoring (library|binary) .*is not included in the published package|ignoring `package.build`|the exclude list will be ignored' "$G/pack.err"; then
    echo "SCOPED GREP MATCHED -> fail"; rc=1
  else
    echo "scoped grep clean"
  fi

  echo "--- sub-check 3: packaged manifest target set"
  if [ -f "target/package/${PKG}-${VER}.crate" ]; then tar -xzf "target/package/${PKG}-${VER}.crate" -C "$G/x"; else echo "no .crate produced"; fi
  cargo metadata --no-deps --format-version 1 --offline \
    --manifest-path "$G/x/${PKG}-${VER}/Cargo.toml" \
    | jq -Sc '[.packages[0].targets[] | {name, kind}] | sort_by(.kind[0], .name)' > "$G/targets.json"
  cat "$G/targets.json"
  diff -u "$G/expected-packaged-targets.json" "$G/targets.json" || rc=1
  echo "--- packaged Cargo.toml [[bin]] tables:"
  grep -n -A2 '^\[\[bin\]\]' "$G/x/${PKG}-${VER}/Cargo.toml" || true
  echo "GUARD RESULT ($label): rc=$rc"
  return $rc
}

guard "healthy"; echo "healthy exit=$?"

hr "PHASE 4 — injected fault A: include narrowed so src/bin/rsguard-serve.rs is not packed"
sed -i '' 's|include = .*|include = ["src/lib.rs", "src/main.rs", "Cargo.toml", "README.md"]|' "$W/Cargo.toml"
grep -n '^include' "$W/Cargo.toml"
git add -A && git -c user.email=r26@probe -c user.name=r26 commit -qm faultA
guard "fault A (dropped binary)"; echo "faultA exit=$?"

hr "PHASE 5 — injected fault B: denylist manifest, stray file ships"
sed -i '' 's|include = .*|exclude = ["notes/"]|' "$W/Cargo.toml"
grep -n '^exclude' "$W/Cargo.toml"
echo "probe repo git status (must be clean after commit):"
git add -A && git -c user.email=r26@probe -c user.name=r26 commit -qm faultB
git status --porcelain; echo "(empty above = clean tree)"
guard "fault B (stray file)"; echo "faultB exit=$?"

hr "PHASE 6 — subsidiary claims"
echo "--- --message-format json on stable:"
cargo package -p "$PKG" --list --message-format json --offline > "$G/mf.out" 2>&1; echo "exit=$?"; head -3 "$G/mf.out"
echo "--- dirty working tree:"
echo 'dirt' >> "$W/README.md"
cargo package -p "$PKG" --no-verify --offline > "$G/dirty.out" 2>&1; echo "exit=$?"; tail -4 "$G/dirty.out"
git checkout -q -- README.md
echo "--- stdout/stderr separation of --list (stdout only paths):"
cargo package -p "$PKG" --list --no-verify --offline 2>/dev/null | head -3

hr "PHASE 7 — source repos at their pins"
echo "# ts-launch-blueprint @ cb1cbcb2 .github/workflows/publish.yml"
git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:.github/workflows/publish.yml \
  | grep -n "Assert packed file list\|npm pack --dry-run\|Fail on any npm bin auto-correction\|npm publish --dry-run"
echo "# py-launch-blueprint @ b08bccfb .github/workflows/publish.yml — packed-content assertions?"
git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:.github/workflows/publish.yml \
  | grep -nc "twine check\|check-wheel-contents\|pack --dry-run"
git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:.github/workflows/publish.yml \
  | grep -n "name:" | head -20

hr "DONE"
