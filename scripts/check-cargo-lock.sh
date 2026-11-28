#!/usr/bin/env bash
# Lockfile-freshness check (R41): refuse a commit whose staged Cargo resolution
# inputs (manifests, Cargo.lock, .cargo/config[.toml]) would make any Cargo.lock
# in the repository change.
#
# Runs `cargo update --workspace` (without `--locked`) from each workspace
# root's own directory, compares every Cargo.lock against the index, and
# restores any touched lockfile so a refusal never leaves the worktree modified.
#
# Usage: scripts/check-cargo-lock.sh          # pre-commit: staged-input trigger
#        scripts/check-cargo-lock.sh --all    # CI: unconditional full-tree check
# Env:   CARGO_BIN (default: cargo on PATH)
# Exit:  0 fresh or skipped; 1 a Cargo.lock would change, or a parity/untracked
#        refusal; otherwise Cargo's own status (validation could not complete).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# Exclude archived P01/P02 research fixtures under research/ (stripped in stamped child repos).
paths=(':(glob)**/Cargo.toml' ':(glob)**/Cargo.lock'
       ':(glob)**/.cargo/config' ':(glob)**/.cargo/config.toml'
       ':!research/')
locks=(':(glob)**/Cargo.lock' ':!research/')

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

untracked=$(git ls-files --others --exclude-standard -- "${paths[@]}")
if [[ -n "$untracked" ]]; then
    echo 'FAIL: untracked Cargo resolution inputs exist. Stage the intended inputs or move unrelated inputs outside this workspace.' >&2
    exit 1
fi

# Workspace root discovery: tracked root Cargo.toml plus any other tracked
# Cargo.toml with a [workspace] table or beside a tracked Cargo.lock that Cargo
# itself confirms as its own workspace root.
roots=()
skipped=0
candidates=$( { git ls-files -- Cargo.toml
                git grep -l -E '^\[workspace(\]|\.)' -- ':(glob)**/Cargo.toml' ':!research/' || true
                git ls-files -- ':(glob)**/Cargo.lock' ':!research/' | sed 's#Cargo\.lock$#Cargo.toml#'
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

# Report any `.cargo/config*` below a workspace root that Cargo would not apply
# when invoked from the root directory.
unapplied=""
while IFS= read -r cfg; do
    [[ -n "$cfg" ]] || continue
    d=$(dirname "$(dirname "$cfg")")
    applied=0
    [[ "$d" == . ]] && applied=1
    for root in ${roots[@]+"${roots[@]}"}; do
        rd=$(dirname "$root")
        if [[ "$rd" == "$d" || "$rd" == "$d"/* ]]; then applied=1; fi
    done
    [[ "$applied" == 1 ]] || unapplied+=" $cfg"
done <<< "$(git ls-files -- ':(glob)**/.cargo/config' ':(glob)**/.cargo/config.toml' ':!research/')"
if [[ -n "$unapplied" ]]; then
    echo "note: Cargo config below a workspace root is not applied by this check (Cargo reads it only for commands run inside that directory):$unapplied" >&2
fi

# Conservative resolve of each root from its own directory.
cargo_log=""
for root in ${roots[@]+"${roots[@]}"}; do
    rootdir=$(dirname "$root")
    if git check-ignore -q "$rootdir/Cargo.lock"; then
        echo "note: $rootdir/Cargo.lock is Git-ignored; that workspace is not checked" >&2
        continue
    fi
    if root_log=$(cd "$rootdir" && "${CARGO_BIN:-cargo}" update --workspace 2>&1); then
        cargo_log+="$root_log"$'\n'
    else
        result=$?
        printf '%s\n' "$root_log" >&2
        echo "FAIL: Cargo lockfile validation could not complete for workspace $rootdir; see Cargo diagnostics above. For cache/network errors, fetch dependencies and retry." >&2
        exit "$result"
    fi
done

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
