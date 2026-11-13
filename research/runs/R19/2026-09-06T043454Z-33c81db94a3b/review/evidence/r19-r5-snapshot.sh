#!/usr/bin/env bash
# R19 dependabot-config-shape — snapshot fetcher for the security-exemption and
# open-PR-budget sentences that essential behaviors 4 and 2 rest on.
#
# Revision 4 established the shape: snapshot the pinned source into this
# directory, bind every file to its commit by its own git blob sha, and assert on
# the bytes. This fetcher does the same thing for the one `github/docs` file the
# decision quotes, at the pin the decision already names,
# `dd75c5f38a14d1c07c3982beddb471a605b142f7`.
#
# Writes the snapshot that `r19-check-r5.sh` asserts on. Run once; it is
# committed so an auditor can regenerate the snapshot from the pin and confirm it
# is byte-identical to the committed one. Every read is a GET at a literal commit
# sha, so re-running it can only reproduce the same bytes or fail.
#
# Usage:  bash research/runs/R19/2026-09-06T043454Z-33c81db94a3b/review/evidence/r19-r5-snapshot.sh
set -uo pipefail

E="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_SHA=dd75c5f38a14d1c07c3982beddb471a605b142f7
SNAP="$E/github-docs-$(printf '%.8s' "$DOCS_SHA")"
DOC_PATH=content/code-security/reference/supply-chain-security/dependabot-options-reference.md
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

set -e
mkdir -p "$SNAP/$(dirname "$DOC_PATH")"

# 1. The file's git blob sha AT THE PIN. `github/docs` is far too large for a
#    recursive tree read, so the address comes from the contents endpoint with an
#    explicit `?ref=<sha>` — the same pinned reader the main check's DOCS() uses.
BLOB=$(gh api -H "User-Agent: $UA" \
  "repos/github/docs/contents/$DOC_PATH?ref=$DOCS_SHA" --jq '.sha')
printf '%s\t%s\n' "$DOC_PATH" "$BLOB" > "$SNAP/tree.tsv"

# 2. The blob itself, fetched by its own sha rather than by path at a ref, then
#    verified: `git hash-object` re-derives the content address offline, so the
#    snapshot is cryptographically bound to commit $DOCS_SHA and not merely dated.
gh api -H "User-Agent: $UA" -H 'Accept: application/vnd.github.raw' \
  "repos/github/docs/git/blobs/$BLOB" > "$SNAP/$DOC_PATH"
H=$(git hash-object -t blob "$SNAP/$DOC_PATH")
[ "$H" = "$BLOB" ] || { printf 'blob sha mismatch: %s != %s\n' "$H" "$BLOB" >&2; exit 1; }

printf 'snapshot written to %s\n' "$SNAP"
printf '%s  %s\n' "$BLOB" "$DOC_PATH"
wc -l < "$SNAP/$DOC_PATH"
