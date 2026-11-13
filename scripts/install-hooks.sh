#!/usr/bin/env bash
# Install the native pre-commit hook without replacing another hook setup.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
if git config --get core.hooksPath >/dev/null; then
    echo "Custom core.hooksPath is configured; integrate .githooks/pre-commit into that setup." >&2
    exit 1
fi
hook=$(git rev-parse --git-path hooks/pre-commit)
if [ -e "$hook" ] || [ -L "$hook" ]; then
    if cmp -s .githooks/pre-commit "$hook"; then
        chmod +x "$hook"
        echo "ShellCheck pre-commit hook already installed."
        exit 0
    fi
    echo "Existing pre-commit hook preserved: $hook; integrate .githooks/pre-commit manually." >&2
    exit 1
fi
mkdir -p "$(dirname "$hook")"
install -m 755 .githooks/pre-commit "$hook"
echo "Installed ShellCheck pre-commit hook: $hook"
