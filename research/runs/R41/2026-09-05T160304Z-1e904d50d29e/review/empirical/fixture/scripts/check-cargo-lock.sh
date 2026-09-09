#!/usr/bin/env bash
# Lockfile-freshness check (R41, decision revision 4): refuse a commit whose
# staged Cargo resolution inputs (manifests, Cargo.lock, .cargo/config[.toml])
# would make any Cargo.lock in the repository change. The test is the one
# `uv lock --check` makes -- "would the lockfile change after a resolution?" --
# realized, for every workspace root in the repository, as a conservative
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
# One `cargo update --workspace` resolves one workspace. Cargo.lock lives at a
# workspace root, and a repository may hold independent workspaces beneath its
# top level (a package with its own [workspace] table, or one listed in the
# top-level workspace.exclude), so every such root is resolved separately
# (empirical audit r3, finding F1). Roots are the tracked top-level Cargo.toml,
# plus every other tracked Cargo.toml that declares a [workspace] table or sits
# beside a tracked Cargo.lock and that Cargo itself reports as its own workspace
# root (`cargo locate-project --workspace`). Candidates Cargo rejects -- a
# non-member package under another workspace, a vendored crate, an unparsable
# template manifest -- are skipped, because Cargo cannot resolve them from there
# either. A single-workspace repository therefore runs no extra Cargo process.
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
# Exit:  0 fresh or skipped; 1 a Cargo.lock would change, or a parity/untracked
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

# Workspace roots (see the header). Discovery runs after the guards above, so
# the index and worktree agree for every candidate manifest it reads.
roots=()
skipped=0
candidates=$( { git ls-files -- Cargo.toml
                git grep -l -E '^\[workspace(\]|\.)' -- ':(glob)**/Cargo.toml' || true
                git ls-files -- ':(glob)**/Cargo.lock' | sed 's#Cargo\.lock$#Cargo.toml#'
              } | sort -u )
while IFS= read -r m; do
    [[ -n "$m" && -f "$m" ]] || continue
    if [[ "$m" == Cargo.toml ]]; then roots+=("$m"); continue; fi
    if located=$("${CARGO_BIN:-cargo}" locate-project --workspace --message-format plain --manifest-path "$m" 2>/dev/null) \
       && [[ "$(cd "$(dirname "$located")" && pwd -P)" == "$(cd "$(dirname "$m")" && pwd -P)" ]]; then
        roots+=("$m")
    else
        skipped=$((skipped+1))
    fi
done <<< "$candidates"
if [[ "$skipped" -gt 0 ]]; then
    echo "note: $skipped candidate manifest(s) skipped: Cargo does not treat them as workspace roots" >&2
fi
if [[ ${#roots[@]} -eq 0 ]]; then
    echo 'FAIL: no Cargo workspace root found in the repository (expected a tracked top-level Cargo.toml, a manifest with a [workspace] table, or a manifest beside a tracked Cargo.lock).' >&2
    exit 1
fi

# Conservative resolve of each root. Cargo writes Cargo.lock only when its
# contents would change (src/ops/lockfile.rs, write_pkg_lockfile), so a fresh
# lockfile is not touched. Cargo's log (Adding/Removing/Updating lines) is shown
# only on failure.
cargo_log=""
for root in ${roots[@]+"${roots[@]}"}; do
    if root_log=$("${CARGO_BIN:-cargo}" update --workspace --manifest-path "$root" 2>&1); then
        cargo_log+="$root_log"$'\n'
    else
        result=$?
        printf '%s\n' "$root_log" >&2
        echo "FAIL: Cargo lockfile validation could not complete for workspace $root; see Cargo diagnostics above. For cache/network errors, fetch dependencies and retry." >&2
        exit "$result"
    fi
done

# Any Cargo.lock now differing from the index, or created by the resolve, means
# the staged inputs need a lockfile change. Show what changed, then restore.
changed=$(git diff --name-only --no-ext-diff --no-renames -- "${locks[@]}")
created=$(git ls-files --others --exclude-standard -- "${locks[@]}")
if [[ -n "$changed" || -n "$created" ]]; then
    printf '%s' "$cargo_log" >&2
    if [[ -n "$changed" ]]; then
        git --no-pager diff --stat --no-ext-diff --no-renames -- "${locks[@]}" >&2
        git checkout --quiet -- "${locks[@]}"
    fi
    if [[ -n "$created" ]]; then
        printf 'would create: %s\n' "$created" >&2
        printf '%s\n' "$created" | while IFS= read -r f; do rm -f -- "$f"; done
    fi
    echo 'FAIL: Cargo.lock is out of date for the staged Cargo inputs (it would change; restored, nothing was modified). Run cargo update --workspace in the directory of each Cargo.lock listed above, review the Cargo.lock diff, stage Cargo.lock with the intended manifests, and commit again.' >&2
    exit 1
fi
exit 0
