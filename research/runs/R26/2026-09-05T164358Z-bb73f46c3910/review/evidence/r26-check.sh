#!/usr/bin/env bash
# R26 packed-artifact-content-guard — synthesizer empirical check.
# Verifies claims only. Publishes nothing; never invokes `cargo publish`.
# Emits log phases 0-10. Every phase 8-10 assertion compares expected content,
# not an exit code alone, and increments FAILS; the script exits with FAILS.
set -u
set -o pipefail

FAILS=0
assert_eq() { # assert_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf 'PASS %s (%s)\n' "$1" "$3"
  else
    printf 'FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"
    FAILS=$((FAILS + 1))
  fi
}

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

hr "PHASE 8 — stream separation on a clean tree"
echo "target/ is tracked in the probe repo (no .gitignore), so PHASE 6's last sub-step hit the dirty-tree error."
echo "Committing the packaging artifacts, then re-running on a clean tree:"
git add -A && git -c user.email=r26@probe -c user.name=r26 commit -qm pkgartifacts
git status --porcelain; echo "(empty above = clean tree)"
assert_eq "phase8/clean-tree-entries" 0 "$(git status --porcelain | wc -l | tr -d ' ')"
cargo package -p "$PKG" --list --no-verify --offline > "$G/sep.out" 2> "$G/sep.err"
sep_rc=$?
echo "exit=$sep_rc"
assert_eq "phase8/list-exit" 0 "$sep_rc"
echo "--- stdout (first 6 lines):"
head -6 "$G/sep.out"
assert_eq "phase8/stdout-first-path" ".cargo_vcs_info.json" "$(head -1 "$G/sep.out")"
# Cargo emits the list in byte order (C collation), not the host locale's collation:
# `STRAY.txt` precedes `src/…`. A checked-in expectation must be compared the same way.
assert_eq "phase8/stdout-byte-sorted" 0 "$(LC_ALL=C sort -c "$G/sep.out" >/dev/null 2>&1; echo $?)"
assert_eq "phase8/stdout-not-locale-sorted" 1 "$(LC_ALL=en_US.UTF-8 sort -c "$G/sep.out" >/dev/null 2>&1; echo $?)"
assert_eq "phase8/stdout-diagnostic-lines" 0 "$(grep -c 'warning:' "$G/sep.out")"
assert_eq "phase8/stdout-carries-stray" 1 "$(grep -c '^STRAY\.txt$' "$G/sep.out")"
echo "--- stderr:"
cat "$G/sep.err"
assert_eq "phase8/stderr-carries-warning" 1 \
  "$(grep -c 'warning: manifest has no documentation, homepage or repository' "$G/sep.err")"
assert_eq "phase8/stderr-carries-no-paths" 0 "$(grep -c '^src/' "$G/sep.err")"

hr "PHASE 9 — Cargo.toml.orig byte-compare and publish-facing field projection"
ORIG="$G/x/${PKG}-${VER}/Cargo.toml.orig"
NORM="$G/x/${PKG}-${VER}/Cargo.toml"
echo "--- cmp source Cargo.toml vs archive Cargo.toml.orig:"
cmp "$W/Cargo.toml" "$ORIG"
cmp_rc=$?
echo "cmp exit=$cmp_rc"
assert_eq "phase9/orig-byte-identical" 0 "$cmp_rc"
echo "--- normalized packaged Cargo.toml (whole file):"
cat "$NORM"
echo "--- cargo metadata publish-facing projection (Codex field list) from the packaged manifest:"
cargo metadata --no-deps --format-version 1 --offline --manifest-path "$NORM" \
  | jq -S '.packages[0] | {name, version, description, license, license_file, repository,
      homepage, documentation, readme, keywords, categories, rust_version, edition, links,
      publish, default_run,
      targets: [.targets[] | {name, kind, crate_types, required_features}]}' > "$G/proj.json"
proj_rc=$?
cat "$G/proj.json"
echo "metadata exit=$proj_rc"
assert_eq "phase9/projection-exit" 0 "$proj_rc"
assert_eq "phase9/edition" '"2024"' "$(jq -c '.edition' "$G/proj.json")"
assert_eq "phase9/license" '"MIT OR Apache-2.0"' "$(jq -c '.license' "$G/proj.json")"
assert_eq "phase9/readme" '"README.md"' "$(jq -c '.readme' "$G/proj.json")"
assert_eq "phase9/name" '"rsguard"' "$(jq -c '.name' "$G/proj.json")"
assert_eq "phase9/version" '"0.1.0"' "$(jq -c '.version' "$G/proj.json")"
assert_eq "phase9/target-count" 3 "$(jq -c '.targets | length' "$G/proj.json")"

hr "PHASE 10 — stale-archive hazard when cargo package fails"
CRATE="target/package/${PKG}-${VER}.crate"
echo "a .crate from the last successful packaging run is on disk: $CRATE"
assert_eq "phase10/prior-crate-present" 1 "$([ -f "$CRATE" ] && echo 1 || echo 0)"
before_sha=$(shasum -a 256 "$CRATE" | awk '{print $1}')
echo "now make the tree dirty so cargo package fails:"
echo 'dirt' >> "$W/README.md"
cargo package -p "$PKG" --no-verify --offline > "$G/stale.out" 2>&1
stale_rc=$?
echo "cargo package exit=$stale_rc"
grep -m1 'files in the working directory contain changes' "$G/stale.out"
assert_eq "phase10/package-exit" 101 "$stale_rc"
assert_eq "phase10/dirty-error-text" 1 \
  "$(grep -c 'files in the working directory contain changes that were not yet committed into git' "$G/stale.out")"
after_sha=$(shasum -a 256 "$CRATE" | awk '{print $1}')
assert_eq "phase10/stale-crate-survives-failure" "yes" \
  "$([ "$before_sha" = "$after_sha" ] && echo yes || echo no)"
echo "the .crate from the PREVIOUS run is still present, byte-identical, and an unguarded check would extract it:"
rm -rf "$G/stale"; mkdir -p "$G/stale"
tar -xzf "$CRATE" -C "$G/stale"
cargo metadata --no-deps --format-version 1 --offline \
  --manifest-path "$G/stale/${PKG}-${VER}/Cargo.toml" \
  | jq -Sc '[.packages[0].targets[] | {name, kind}] | sort_by(.kind[0], .name)' > "$G/stale-targets.json"
cat "$G/stale-targets.json"
assert_eq "phase10/stale-target-set" \
  '[{"kind":["bin"],"name":"rsguard"},{"kind":["bin"],"name":"rsguard-serve"},{"kind":["lib"],"name":"rsguard"}]' \
  "$(cat "$G/stale-targets.json")"
echo "(that target set was read from the earlier run's archive, not from the current source tree)"
git checkout -q -- README.md

hr "DONE"
echo "failed assertions: $FAILS"
exit "$FAILS"
