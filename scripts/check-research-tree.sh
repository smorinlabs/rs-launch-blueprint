#!/usr/bin/env bash
# Compatibility entrypoint. Python holds the publication lock across both
# the original structural checks and strict acceptance validation.
set -uf
here="$(cd "$(dirname "$0")" && pwd)"
if [ "${1:-}" = "--require-owner-review" ]; then
  shift
  exec python3 "$here/research_validation.py" --legacy-output --require-owner-review check-tree "$@"
fi
exec python3 "$here/research_validation.py" --legacy-output check-tree "$@"
