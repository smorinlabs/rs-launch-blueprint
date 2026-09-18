#!/usr/bin/env bash
# R86 — the snapshot fetcher. This script produced everything under
# snapshots/. It is NOT run by check.sh: the live sources it reads are
# volatile (star counts, issue counts and rendered documentation pages all
# move), so the decision cites the committed snapshots and check.sh asserts
# against those, which keeps check.sh byte-reproducible offline.
#
# Re-run this script when the decision is re-verified. Every retrieval date in
# the decision is the UTC timestamp this script writes into
# snapshots/fetched-at.txt at the start of its run.
#
# `gh` is keyring-authenticated on this machine. No token byte is read,
# printed or stored: `gh` is invoked as a subprocess and only its response
# bodies are saved. No personal email address appears in any User-Agent.

set -euo pipefail

SNAP="$(cd "$(dirname "$0")" && pwd)/snapshots"
mkdir -p "$SNAP"
cd "$SNAP"

UA="rs-launch-blueprint-research/R86 (+https://github.com/smorinlabs/rs-launch-blueprint)"
# The commit the v1.12 and v1 tags both dereference to. Every source file is
# read AT THIS PIN, never at `main`, because `main` carries unreleased commits.
PIN=86365089eb2b84e0a8fb0717b304f8bdcb13b20e

date -u > fetched-at.txt

TMPDIR_NPM="$(mktemp -d "${TMPDIR:-/tmp}/r86-npm-XXXXXX")"
trap 'rm -rf "$TMPDIR_NPM"' EXIT

get() { curl -sS -L --fail --max-time 60 -A "$UA" -o "$2" "$1"; }
# Some pages are fetched for their STATUS as much as their body.
get_status() { curl -sS -L -o "$2" -w '%{http_code}\n' -A "$UA" "$1"; }
contents() { gh api "repos/$1/contents/$2" --jq '.content' | base64 -d > "$3"; }

# --- the vendor's action: identity, versioning, cadence -------------------
gh api repos/openai/codex-action                       > repo-codex-action.json
gh api repos/openai/codex-action/git/ref/tags/v1.12    > ref-tag-v1.12.json
gh api repos/openai/codex-action/git/ref/tags/v1       > ref-tag-v1.json
gh api "repos/openai/codex-action/git/tags/$(python3 -c "import json;print(json.load(open('ref-tag-v1.12.json'))['object']['sha'])")" \
                                                       > tagobj-v1.12.json
gh api "repos/openai/codex-action/git/tags/$(python3 -c "import json;print(json.load(open('ref-tag-v1.json'))['object']['sha'])")" \
                                                       > tagobj-v1.json
gh api repos/openai/codex-action/releases              > releases.json
gh api repos/openai/codex-action/tags --paginate       > tags.json

# --- the action's own source, read at the pin ------------------------------
for path in action.yml README.md CHANGELOG.md docs/security.md \
            src/checkActorPermissions.ts src/main.ts; do
  contents openai/codex-action "${path}?ref=${PIN}" "v1.12--${path//\//_}"
done
gh api "repos/openai/codex-action/contents/examples?ref=${PIN}" --jq '.[].name' > v1.12--examples-listing.txt
gh api "repos/openai/codex-action/contents/src?ref=${PIN}"      --jq '.[].name' > v1.12--src-listing.txt

# --- advisories, issue population, the issues the decision cites -----------
gh api repos/openai/codex-action/security-advisories            > adv-repo-codex-action.json
gh api "advisories?ecosystem=npm&affects=@openai/codex&per_page=100" > adv-npm-openai-codex.json
gh api "advisories?ecosystem=actions&per_page=100"             > adv-actions-ecosystem.json
gh api "search/issues?q=repo:openai/codex-action+is:issue+is:open" > search-open-issues.json
gh api "search/issues?q=repo:openai/codex-action+is:pr+is:open"    > search-open-prs.json
for n in 160 168 169 171 172 175; do
  gh api "repos/openai/codex-action/issues/${n}" > "issue-${n}.json"
done

# --- the npm packages the single codex-version input pins ------------------
# Both registry documents carry a `versions` map of several thousand entries,
# 17 MB between them. They are PRUNED before being committed: `name`,
# `license` and `dist-tags` are kept unaltered; `time` keeps `created`,
# `modified` and the versions this decision cites; `versions` keeps those same
# versions. No value is rewritten.
get https://registry.npmjs.org/@openai/codex                     "$TMPDIR_NPM/codex.json"
get https://registry.npmjs.org/@openai/codex-responses-api-proxy "$TMPDIR_NPM/proxy.json"
python3 - "$TMPDIR_NPM/codex.json" npm-openai-codex.pruned.json \
         "$TMPDIR_NPM/proxy.json" npm-openai-codex-responses-api-proxy.pruned.json <<'PRUNE'
import json, sys
CITED = {"0.154.0", "0.147.0", "0.150.1", "0.138.0", "0.39.0", "0.38.0", "0.23.0"}
for source, target in zip(sys.argv[1::2], sys.argv[2::2]):
    document = json.load(open(source))
    kept = sorted(v for v in document.get("versions", {}) if v in CITED)
    json.dump({
        "name": document.get("name"),
        "license": document.get("license"),
        "dist-tags": document.get("dist-tags"),
        "time": {k: v for k, v in document.get("time", {}).items()
                 if k in CITED or k in ("created", "modified")},
        "versions": {v: {"version": v, "license": document["versions"][v].get("license")}
                     for v in kept},
    }, open(target, "w"), indent=1, sort_keys=True)
PRUNE

# --- the Marketplace question ---------------------------------------------
# `codex-exec-action` is the slug the action's own `name:` would produce.
for slug in codex-exec-action codex-action codex-code-review-actor codex-reviewer; do
  get_status "https://github.com/marketplace/actions/${slug}" "marketplace-${slug}.html" \
    > "marketplace-${slug}.status"
done
get "https://github.com/marketplace?query=codex&type=actions" marketplace-search-codex.html
gh api repos/icoretech/codex-action > repo-icoretech-codex-action.json

# --- the platform's own context-availability table -------------------------
get "https://docs.github.com/en/actions/reference/workflows-and-actions/contexts" gh-contexts.html

# --- the vendor's hosted connector, for the trigger-collision analysis -----
get "https://learn.chatgpt.com/docs/third-party/github" connector-github.html

# --- practice evidence: the adopters' own committed workflow files ---------
contents supabase/cli     .github/workflows/ai-review.yml            adopter-supabase-ai-review.yml
contents supabase/cli     .github/ai-review/README.md                adopter-supabase-ai-review-README.md
contents trailofbits/coop .github/workflows/codex-review.yml         adopter-trailofbits-codex-review.yml
contents astral-sh/uv     .github/workflows/update-issue-context.yml adopter-uv-update-issue-context.yml

echo "snapshots refreshed at $(cat fetched-at.txt)"
