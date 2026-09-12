#!/usr/bin/env bash
# R49 check L — under what conditions Cargo includes Cargo.lock in a package.
# Read-only: fetches documentation and source at the rust-1.98.0 tag of
# rust-lang/cargo (the tag matching the installed toolchain) and prints the
# installed cargo's own help. Scaffolds nothing, builds nothing, publishes
# nothing. Every probe asserts on content, not on an exit code alone.
set -u
set -o pipefail

fail=0
tag=rust-1.98.0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

need() { # need <label> <file> <pattern>
  if grep -qF -- "$3" "$2"; then
    printf 'ASSERT ok   %s\n' "$1"
  else
    printf 'ASSERT FAIL %s (missing: %s)\n' "$1" "$3"
    fail=1
  fi
}

fetch() { # fetch <repo-path> <outfile> <expected-sha256-or-->
  if ! gh api "repos/rust-lang/cargo/contents/$1?ref=$tag" --jq '.content' \
      | base64 -d > "$2"; then
    printf 'FETCH FAIL %s\n' "$1"
    fail=1
    return 1
  fi
  local got
  got="$(shasum -a 256 "$2" | cut -d' ' -f1)"
  printf '=== %s@%s ===\nbytes: %s  sha256: %s\n' \
    "$1" "$tag" "$(wc -c < "$2" | tr -d ' ')" "$got"
  if [ "$3" != "-" ] && [ "$got" != "$3" ]; then
    printf 'DIGEST FAIL %s expected %s\n' "$1" "$3"
    fail=1
  fi
}

echo '# R49 check L — conditions under which Cargo.lock is included in a package'
printf 'retrieved: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'installed: %s\n' "$(cargo --version)"
printf 'installed: %s\n' "$(rustc --version)"
echo

# --- 1. manifest reference: the lockfile versus include/exclude -------------
fetch src/doc/src/reference/manifest.md "$tmp/manifest.md" \
  28e0aaa4907a85fd7c8bc45e68a6fb4bac997913edaff83500cd63ca608a215b || true
if [ -s "$tmp/manifest.md" ]; then
  awk '/^The following files are always included:$/,/^The options are mutually/' \
    "$tmp/manifest.md"
  need 'manifest.md says the lockfile is automatically included' \
    "$tmp/manifest.md" 'A minimized `Cargo.lock` is automatically included.'
  need 'manifest.md scopes that list to include/exclude' \
    "$tmp/manifest.md" 'Regardless of whether `exclude` or `include` is specified'
fi
echo

# --- 2. cargo package reference: the command-line override ------------------
fetch src/doc/src/commands/cargo-package.md "$tmp/cargo-package.md" \
  257f6fd4b6b885e42edb01149c6981da5117fde0226f10a0250c0ea74119399f || true
if [ -s "$tmp/cargo-package.md" ]; then
  grep -n -A2 -- '`Cargo.lock` is always included' "$tmp/cargo-package.md"
  grep -n -A4 -- 'option-cargo-package---exclude-lockfile' "$tmp/cargo-package.md"
  need 'cargo-package.md names --exclude-lockfile as the override' \
    "$tmp/cargo-package.md" 'generated unless the `--exclude-lockfile` flag is used'
  need 'cargo-package.md documents what the flag does' \
    "$tmp/cargo-package.md" 'Don’t include the lock file when packaging.'
fi
echo

# --- 3. the installed cargo's own effective help ----------------------------
echo '=== cargo package --help (installed) ==='
if cargo package --help > "$tmp/package-help.txt" 2>&1; then
  grep -n -- '--exclude-lockfile' "$tmp/package-help.txt"
  need 'installed cargo offers --exclude-lockfile with no -Z gate' \
    "$tmp/package-help.txt" "--exclude-lockfile         Don't include the lock file when packaging"
else
  echo 'HELP FAIL cargo package --help'
  fail=1
fi
echo

# --- 4. source: where the condition lives -----------------------------------
fetch src/bin/cargo/commands/package.rs "$tmp/cmd-package.rs" - || true
if [ -s "$tmp/cmd-package.rs" ]; then
  grep -n -- 'include_lockfile' "$tmp/cmd-package.rs"
  need 'cargo package maps the flag to include_lockfile' \
    "$tmp/cmd-package.rs" 'include_lockfile: !args.flag("exclude-lockfile")'
fi

fetch src/cargo/ops/cargo_package/mod.rs "$tmp/pkg-mod.rs" - || true
if [ -s "$tmp/pkg-mod.rs" ]; then
  grep -n -- '"Cargo.lock" => continue' "$tmp/pkg-mod.rs"
  grep -n -A10 -- '^    if include_lockfile {' "$tmp/pkg-mod.rs"
  need 'an on-disk Cargo.lock is dropped from the source file list' \
    "$tmp/pkg-mod.rs" '"Cargo.lock" => continue'
  need 'the archive entry is added only when include_lockfile is set' \
    "$tmp/pkg-mod.rs" 'if include_lockfile {'
  need 'an absent lockfile is generated rather than omitted' \
    "$tmp/pkg-mod.rs" 'let lockfile_path = lockfile_path.exists().then_some(lockfile_path);'
fi

fetch src/cargo/ops/registry/publish.rs "$tmp/publish.rs" - || true
if [ -s "$tmp/publish.rs" ]; then
  grep -n -- 'include_lockfile' "$tmp/publish.rs"
  need 'the publish path hardcodes inclusion, so it has no override' \
    "$tmp/publish.rs" 'include_lockfile: true,'
fi
echo

if [ "$fail" -eq 0 ]; then
  echo 'RESULT all assertions passed'
else
  echo 'RESULT one or more assertions failed'
fi
exit "$fail"
