#!/usr/bin/env bash
# Compatibility wrapper for the Python validator. Bash 3.2 users retain the
# historical stdout FAIL surface; runner integrations use the Python JSON CLI.
set -uf
here="$(cd "$(dirname "$0")" && pwd)"
f="${1:?answer file}"; kind="${2:?kind}"; ov="${3:-}"
if [ "$ov" = override ]; then
  python3 "$here/research_validation.py" --legacy-output answer "$f" "$kind" override
else
  python3 "$here/research_validation.py" --legacy-output answer "$f" "$kind"
fi
