#!/usr/bin/env bash
# Lockfile-freshness check (R41, decision revision 3): refuse a commit whose
# staged Cargo resolution inputs (manifests, Cargo.lock, .cargo/config[.toml])
# would make Cargo.lock change. The test is the one `uv lock --check` makes --
# "would the lockfile change after a resolution?" -- realized as a conservative
# unlocked resolve (`cargo update --workspace`: workspace members re-read, other
# packages touched only if absent from the lockfile) followed by a Git
# comparison of every Cargo.lock against the index. Whatever Cargo wrote is
# restored from the index before the script exits, so a refusal never leaves
# the worktree modified.
#
# Cargo's own `--locked` is not this test: Cargo's lockfile parser drops path
# packages that are no longer in the workspace (src/resolver/encode.rs, "It must
# have been removed and should be ignored") and `--locked` compares parsed
# resolves rather than file contents (src/ops/lockfile.rs, are_equal_lockfiles),
# so a removed leaf workspace member leaves an orphan [[package]] entry that
# every `--locked` command accepts and the next unlocked Cargo run silently
# prunes (judgment audit r2, finding F1). The Git comparison catches that case,
# and also refuses a lockfile that Cargo would merely normalize.
#
# Runs Cargo only when such an input is staged, and refuses to run it while any
# such input differs between the index and the worktree or exists untracked and
# not Git-ignored, so a repaired but unstaged lockfile cannot make a broken
# commit pass. The restore step relies on that guard: worktree == index for
# every Cargo.lock before Cargo runs.
#
# Usage: scripts/check-cargo-lock.sh          # pre-commit: staged-input trigger
#        scripts/check-cargo-lock.sh --all    # CI: unconditional full-tree check
# Env:   CARGO_BIN (default: cargo on PATH)
# Exit:  0 fresh or skipped; 1 Cargo.lock would change, or a parity/untracked
#        refusal; otherwise Cargo's own status (validation could not complete).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
paths=(':(glob)**/Cargo.toml' ':(glob)**/Cargo.lock'
       ':(glob)**/.cargo/config' ':(glob)**/.cargo/config.toml')
locks=(':(glob)**/Cargo.lock')

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
# target/package written by `cargo package`, or a Git-ignored relocated
# build.target-dir) lives there. An ignored path dependency is therefore
# unsupported.
untracked=$(git ls-files --others --exclude-standard -- "${paths[@]}")
if [[ -n "$untracked" ]]; then
    echo 'FAIL: untracked Cargo resolution inputs exist. Stage the intended inputs or move unrelated inputs outside this workspace.' >&2
    exit 1
fi

# Conservative resolve. Cargo writes Cargo.lock only when its contents would
# change (src/ops/lockfile.rs, write_pkg_lockfile), so a fresh lockfile is not
# touched. Cargo's log (Adding/Removing/Updating lines) is shown only on failure.
if cargo_log=$("${CARGO_BIN:-cargo}" update --workspace 2>&1); then
    :
else
    result=$?
    printf '%s\n' "$cargo_log" >&2
    echo 'FAIL: Cargo lockfile validation could not complete; see Cargo diagnostics above. For cache/network errors, fetch dependencies and retry.' >&2
    exit "$result"
fi

# Any Cargo.lock now differing from the index, or created by the resolve, means
# the staged inputs need a lockfile change. Show what changed, then restore.
changed=$(git diff --name-only --no-ext-diff --no-renames -- "${locks[@]}")
created=$(git ls-files --others --exclude-standard -- "${locks[@]}")
if [[ -n "$changed" || -n "$created" ]]; then
    printf '%s\n' "$cargo_log" >&2
    if [[ -n "$changed" ]]; then
        git --no-pager diff --stat --no-ext-diff --no-renames -- "${locks[@]}" >&2
        git checkout --quiet -- "${locks[@]}"
    fi
    if [[ -n "$created" ]]; then
        printf 'would create: %s\n' "$created" >&2
        printf '%s\n' "$created" | while IFS= read -r f; do rm -f -- "$f"; done
    fi
    echo 'FAIL: Cargo.lock is out of date for the staged Cargo inputs (it would change; restored, nothing was modified). Run cargo update --workspace, review the Cargo.lock diff, stage Cargo.lock with the intended manifests, and commit again.' >&2
    exit 1
fi
exit 0
