#!/usr/bin/env bash
# Lockfile-freshness check (R41): refuse a commit whose staged Cargo resolution
# inputs (manifests, Cargo.lock, .cargo/config[.toml]) would require Cargo.lock
# to change. Runs Cargo only when such an input is staged, and refuses to run it
# while any such input differs between the index and the worktree, so a repaired
# but unstaged lockfile cannot make a broken commit pass.
#
# Adapted from the R41 research prototype raw/fixture-r41/hook.sh (2026-09-05):
# same pathspecs, same guard order, same command. Two differences: R41_CARGO is
# renamed CARGO_BIN, and the untracked-input scan passes --exclude-standard
# (judgment audit r1, finding F1: the prototype also scanned Git-ignored paths,
# so Cargo's own build output - target/package/<crate>-<version>/Cargo.toml and
# Cargo.lock written by `cargo package` verification - made it refuse).
#
# Usage: scripts/check-cargo-lock.sh          # pre-commit: staged-input trigger
#        scripts/check-cargo-lock.sh --all    # CI: unconditional full-tree check
# Env:   CARGO_BIN (default: cargo on PATH)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
paths=(':(glob)**/Cargo.toml' ':(glob)**/Cargo.lock'
       ':(glob)**/.cargo/config' ':(glob)**/.cargo/config.toml')

if [[ "${1:-}" != --all ]]; then
    if git diff --cached --quiet --no-ext-diff --no-renames -- "${paths[@]}"; then
        echo 'SKIP: no staged Cargo resolution inputs' >&2
        exit 0
    else
        result=$?
        [[ "$result" == 1 ]] || exit "$result"
    fi
fi

if ! git diff --quiet --no-ext-diff --no-renames -- "${paths[@]}"; then
    echo 'FAIL: Cargo resolution inputs differ from the index. Stage the intended manifests, config and lockfile together, or restore the unstaged edits.' >&2
    exit 1
fi

# Untracked but not ignored inputs refuse: Cargo can resolve an untracked path
# dependency that the commit would omit. Ignored paths are never scanned: no
# commit can contain them, and Cargo's own build output (target/, including
# target/package written by `cargo package`, or a relocated build.target-dir)
# lives there. An ignored path dependency is therefore unsupported.
untracked=$(git ls-files --others --exclude-standard -- "${paths[@]}")
if [[ -n "$untracked" ]]; then
    echo 'FAIL: untracked Cargo resolution inputs exist. Stage the intended inputs or move unrelated inputs outside this workspace.' >&2
    exit 1
fi

if "${CARGO_BIN:-cargo}" metadata --locked --format-version=1 >/dev/null; then
    exit 0
else
    result=$?
    echo 'FAIL: Cargo lockfile validation could not complete; see Cargo diagnostics above.' >&2
    echo 'If Cargo requires a lockfile update, run cargo metadata --format-version=1, review Cargo.lock, and stage it with the intended manifests. For cache/network errors, fetch dependencies and retry.' >&2
    exit "$result"
fi
