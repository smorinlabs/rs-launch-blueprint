#!/usr/bin/env bash
# Check tracked shell scripts, including hidden directories and paths with spaces.
# Explicit arguments let git hooks check only staged paths.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
command -v shellcheck >/dev/null 2>&1 || {
    echo "ShellCheck missing: run bash scripts/install-shellcheck.sh and add ~/.local/bin to PATH" >&2
    exit 1
}
if [ "$#" -gt 0 ]; then
    exec shellcheck -- "$@"
fi
# Recorded research evidence predates this check and is validated by its
# recorded run, so a listed script is skipped while its bytes still match.
# A changed or new evidence script is checked in full.
baseline=scripts/shellcheck-evidence-baseline.txt
sha256() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
files=()
while IFS= read -r -d '' file; do
    [ -f "$file" ] || continue
    case "$file" in
        research/runs/*)
            if [ -f "$baseline" ] && grep -Fxq "$(sha256 "$file")  $file" "$baseline"; then
                continue
            fi ;;
    esac
    files+=("$file")
done < <(git ls-files -z -- '*.sh' '*.bash' '.githooks/pre-commit')
if [ "${#files[@]}" -gt 0 ]; then
    shellcheck -- "${files[@]}"
fi
