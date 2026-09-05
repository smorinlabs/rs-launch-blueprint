#!/usr/bin/env bash
# Gate 3 dependency audit for the pinned `committed` release: runs `cargo audit`
# against the lockfile shipped inside the published crate (the lockfile that
# `cargo install --locked` and the tag's release builds both use) and prints the
# reachability evidence (which git2/anyhow APIs committed's own sources call).
# Run from this directory:  bash audit-deps.sh      (COMMITTED_VERSION overrides the pin)
# Exit status is cargo audit's: 0 = no vulnerabilities (unsound/notice
# advisories are reported as warnings and do not fail the run).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${COMMITTED_VERSION:-1.1.11}"
WORK="$HERE/.audit-work"; rm -rf "$WORK"; mkdir -p "$WORK"; trap 'rm -rf "$WORK"' EXIT
echo "R38 gate-3 dependency audit: committed $VERSION"
echo "date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "cwd: $HERE"
echo "toolchain: $(rustc --version); $(cargo --version); $(cargo audit --version)"
cd "$WORK"
curl -sS -L -m 120 -o crate.tgz "https://static.crates.io/crates/committed/committed-$VERSION.crate" && tar -xzf crate.tgz
cd "committed-$VERSION"
echo "--- manifest requirements (Cargo.toml.orig, the author's manifest; the published Cargo.toml is cargo-normalized) ---"; grep -nE '^(git2|anyhow) ' Cargo.toml.orig
echo "--- pinned versions (published Cargo.lock) ---"
for c in git2 libgit2-sys anyhow; do printf '%s = %s\n' "$c" "$(awk -v n="$c" '$0=="name = \""n"\"" {getline; print $3}' Cargo.lock | tr -d '"')"; done
echo "--- cargo audit --file Cargo.lock ---"
cargo audit --file Cargo.lock; RC=$?
echo "cargo audit exit=$RC"
echo "--- reachability: git2 and anyhow API surface used by committed's sources ---"
grep -n "git2::\|Repository::\|revwalk\|Revwalk\|\.author()\|\.message()\|\.parent_count()\|short_id\|Oid" src/*.rs | sed 's/^/   /'
echo "--- downcast / unsafe occurrences in committed's sources ---"
printf '   downcast: %s\n' "$(grep -c "downcast" src/*.rs | awk -F: '{s+=$2} END {print s}')"
printf '   unsafe:   %s\n' "$(grep -c "unsafe" src/*.rs | awk -F: '{s+=$2} END {print s}')"
printf '   Remote::/.remote(/remotes(/blame(/BlameHunk/Buf type (the APIs RUSTSEC-2026-0183/0184 concern): %s\n' "$(grep -cE 'Remote::|\.remote\(|remotes\(|blame\(|BlameHunk|\bBuf\b' src/*.rs | awk -F: '{s+=$2} END {print s}')"
printf '   (a plain substring grep for Buf also matches std::path::PathBuf, which is why the type is matched as a whole word)\n'
exit $RC
