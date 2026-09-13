#!/usr/bin/env bash
# R19 dependabot-config-shape — snapshot fetcher for the MSRV / `rust-version` claim.
#
# Writes the pinned snapshot that `r19-check-5f.sh` asserts on. Run once; it is
# committed so an auditor can regenerate the snapshot from the pin and confirm it
# is byte-identical to the committed one. Every read is a GET at a literal commit
# sha, so re-running it can only reproduce the same bytes or fail.
#
# Usage:  bash review/evidence/r19-5f-snapshot.sh
set -uo pipefail

E="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBC_SHA=1abafc5ca0900334fd970832e9ef43f2afc78233
SNAP="$E/dependabot-core-$(printf '%.8s' "$DBC_SHA")"
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

# The two paths that carry the claim: Cargo's whole runtime library, and the one
# shared file that implements the language/MSRV filter Cargo inherits.
KEEP_JQ='.tree[]
  | select(.type=="blob")
  | select((.path|startswith("cargo/lib/"))
           or .path=="common/lib/dependabot/package/package_latest_version_finder.rb")
  | [.path,.sha] | @tsv'

set -e
mkdir -p "$SNAP"

# 1. The pin's own tree, which supplies each file's git blob sha. A git blob sha
#    is a content address, so `git hash-object` over the saved file re-derives it
#    offline: the snapshot is cryptographically bound to this commit.
gh api -H "User-Agent: $UA" "repos/dependabot/dependabot-core/git/trees/$DBC_SHA?recursive=1" \
  --jq "$KEEP_JQ" | LC_ALL=C sort > "$SNAP/tree.tsv"

# 2. Each blob, fetched by its own sha (not by path at a ref), and verified.
while IFS=$'\t' read -r p s; do
  mkdir -p "$SNAP/$(dirname "$p")"
  gh api -H "User-Agent: $UA" -H 'Accept: application/vnd.github.raw' \
    "repos/dependabot/dependabot-core/git/blobs/$s" > "$SNAP/$p"
  h=$(git hash-object -t blob "$SNAP/$p")
  [ "$h" = "$s" ] || { printf 'blob sha mismatch for %s: %s != %s\n' "$p" "$h" "$s" >&2; exit 1; }
done < "$SNAP/tree.tsv"

# 3. The corroborating live record, snapshotted at retrieval. Unlike the files
#    above this one has no pin: it is a mutable GitHub issue, and the snapshot is
#    what makes the citation reproducible. The retrieval date is recorded in the
#    decision and in the sibling `.retrieved` file.
gh api -H "User-Agent: $UA" repos/dependabot/dependabot-core/issues/5423 \
  --jq '{number,state,created_at,updated_at,comments,title,html_url}' > "$E/issue-5423.json"
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$E/issue-5423.retrieved"

printf 'snapshot written to %s (%s files)\n' "$SNAP" "$(wc -l < "$SNAP/tree.tsv" | tr -d ' ')"
shasum -a 256 "$E/issue-5423.json"
