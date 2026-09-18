#!/usr/bin/env bash
# R86 — codex-assisted-review-workflows — evidence checks for review/DECISION.md
# (revision 1).
#
# Every check asserts on CONTENT, never on an exit code alone, and prints one
# stable `PASS`/`FAIL`/`SKIP` line per check id. The three counts are printed
# and summed at the end; the script exits non-zero on any FAIL.
#
# The live sources this decision cites — the GitHub API, the npm registry,
# GitHub's own documentation, the vendor's hosted-connector page, the GitHub
# Marketplace and four adopters' committed workflow files — are VOLATILE: star
# counts move, issue counts move, and rendered documentation pages are
# re-templated. They were therefore fetched ONCE by `fetch.sh` beside this
# script, at the UTC timestamp in snapshots/fetched-at.txt, and committed under
# snapshots/. This script asserts against the committed snapshots. It is
# therefore byte-reproducible in place AND from a clean `git archive HEAD`
# extraction, and it needs no network. `fetch.sh` is the thing to re-run when
# the decision is re-verified; a figure that has moved since will show up as a
# FAIL here, which is the intended behaviour.
#
# Two snapshots are PRUNED rather than whole, and the pruning is named here
# rather than left to be discovered: the two npm registry documents carry a
# `versions` map with 4551 and 1500-odd entries, 17 MB between them, so
# `fetch.sh` writes `*.pruned.json` holding the document's own `name`,
# `license` and `dist-tags` keys unaltered, its `time` entries for `created`,
# `modified` and the seven versions this decision cites, and `versions`
# restricted to those same seven. No value is rewritten; entries this decision
# does not cite are dropped.
#
# The only live tool this script runs is `actionlint` against the committed
# fixtures. Its path and version are printed. If it is absent, the five L*
# checks print `SKIP` by name rather than silently disappearing.
#
# No token byte, credential value or personal email address is read, printed
# or stored anywhere in this run.

# shellcheck disable=SC2016  # the needles are literal quotations; `$` and backticks inside them must NOT expand.
# shellcheck disable=SC2329  # cleanup() is invoked indirectly, by the EXIT trap below.

set -euo pipefail

GREP=/usr/bin/grep
PASSED=0
FAILURES=0
SKIPPED=0

EVIDENCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAP="$EVIDENCE_DIR/snapshots"
RUN_DIR="$(cd "$EVIDENCE_DIR/../.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r86-check-XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass() { echo "PASS $1 $2"; PASSED=$((PASSED + 1)); }
fail() { echo "FAIL $1 $2"; FAILURES=$((FAILURES + 1)); }
skip() { echo "SKIP $1 $2"; SKIPPED=$((SKIPPED + 1)); }

# assert_contains <id> <file> <needle> <label>
assert_contains() {
  local id="$1" file="$2" needle="$3" label="$4" n
  if [ ! -s "$file" ]; then
    fail "$id" "$label (missing or empty input: ${file##*/})"
    return 0
  fi
  n="$("$GREP" -c -F -- "$needle" "$file" || true)"
  if [ "${n:-0}" -ge 1 ]; then
    pass "$id" "$label [/usr/bin/grep -c -F matches=$n]"
  else
    fail "$id" "$label [/usr/bin/grep -c -F matches=0]"
  fi
}

# assert_absent <id> <file> <needle> <label>
assert_absent() {
  local id="$1" file="$2" needle="$3" label="$4" n
  if [ ! -s "$file" ]; then
    fail "$id" "$label (missing or empty input: ${file##*/})"
    return 0
  fi
  n="$("$GREP" -c -F -- "$needle" "$file" || true)"
  if [ "${n:-0}" -eq 0 ]; then
    pass "$id" "$label [/usr/bin/grep -c -F matches=0]"
  else
    fail "$id" "$label [/usr/bin/grep -c -F matches=$n]"
  fi
}

# assert_json <id> <file> <python-expr over `d`> <expected> <label>
assert_json() {
  local id="$1" file="$2" expr="$3" expected="$4" label="$5" got
  if [ ! -s "$file" ]; then
    fail "$id" "$label (missing or empty input: ${file##*/})"
    return 0
  fi
  got="$(python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
print($expr)
" "$file" 2> "$WORK/json.err" || true)"
  if [ -z "$got" ] && [ -s "$WORK/json.err" ]; then
    fail "$id" "$label (python3 failed: $(tr '\n' ' ' < "$WORK/json.err"))"
    return 0
  fi
  if [ "$got" = "$expected" ]; then
    pass "$id" "$label [= $got]"
  else
    fail "$id" "$label [expected '$expected', got '$got']"
  fi
}

# assert_file_equals <id> <file> <expected contents, trimmed> <label>
assert_file_equals() {
  local id="$1" file="$2" expected="$3" label="$4" got
  if [ ! -s "$file" ]; then
    fail "$id" "$label (missing or empty input: ${file##*/})"
    return 0
  fi
  got="$(tr -d ' \n' < "$file")"
  if [ "$got" = "$expected" ]; then
    pass "$id" "$label [= $got]"
  else
    fail "$id" "$label [expected '$expected', got '$got']"
  fi
}

sha_of() { shasum -a 256 "$1" | cut -d' ' -f1; }

echo "=== R86 evidence checks ==="
echo "evidence dir: $EVIDENCE_DIR"
echo "binaries:"
echo "  /usr/bin/grep: $("$GREP" --version | head -1)"
echo "  python3: $(python3 --version 2>&1)"
if command -v actionlint > /dev/null 2>&1; then
  echo "  actionlint: $(command -v actionlint) version $(actionlint --version | head -1)"
else
  echo "  actionlint: ABSENT"
fi
echo "  shasum: $(shasum --version 2>&1 | head -1)"
echo "  uname: $(uname -srm)"
echo "snapshots fetched at (UTC): $(cat "$SNAP/fetched-at.txt" 2> /dev/null || echo MISSING)"
echo

# ---------------------------------------------------------------------------
# V — a first-party Codex GitHub Action exists: its coordinate, its version,
#     its release cadence. (HIGH question 1.)
# ---------------------------------------------------------------------------
assert_json V01 "$SNAP/repo-codex-action.json" "d['full_name']" "openai/codex-action" \
  'the repository coordinate is openai/codex-action'
assert_json V02 "$SNAP/repo-codex-action.json" "d['owner']['login']+'/'+d['owner']['type']" "openai/Organization" \
  'it belongs to the openai organisation, so the action is first-party'
assert_json V03 "$SNAP/repo-codex-action.json" "str(d['archived'])+'/'+str(d['fork'])+'/'+str(d['private'])" "False/False/False" \
  'it is not archived, not a fork and not private'
assert_json V04 "$SNAP/repo-codex-action.json" "d['license']['spdx_id']" "Apache-2.0" \
  "the action's own source tree is Apache-2.0 (metadata only; fitness gate 1 is inapplicable by owner ruling)"
assert_contains V05 "$SNAP/v1.12--action.yml" 'author: "OpenAI"' \
  'action.yml names the vendor as the action author'
assert_contains V06 "$SNAP/v1.12--action.yml" 'name: "Codex Exec Action"' \
  'action.yml names the action Codex Exec Action'
assert_json V07 "$SNAP/releases.json" "len(d)" "0" \
  'the project publishes NO GitHub Releases, so the version is carried by git tags plus CHANGELOG.md'
assert_json V08 "$SNAP/tags.json" "[t['commit']['sha'] for t in d if t['name']=='v1.12'][0]" \
  "86365089eb2b84e0a8fb0717b304f8bdcb13b20e" 'the v1.12 tag names commit 86365089eb2b84e0a8fb0717b304f8bdcb13b20e'
assert_json V09 "$SNAP/tags.json" "[t['commit']['sha'] for t in d if t['name']=='v1'][0]" \
  "86365089eb2b84e0a8fb0717b304f8bdcb13b20e" 'the MOVING v1 tag names the same commit at snapshot time'
assert_json V10 "$SNAP/tagobj-v1.12.json" "d['object']['type']+' '+d['object']['sha']" \
  "commit 86365089eb2b84e0a8fb0717b304f8bdcb13b20e" \
  'v1.12 is an ANNOTATED tag whose own object sha differs from the commit it dereferences to'
assert_json V11 "$SNAP/ref-tag-v1.12.json" "d['object']['sha']" "cac08775a978ba35a8174558cd9fabab2c09670c" \
  'the v1.12 TAG OBJECT sha, which is not the sha a `uses:` pin would carry'
assert_json V12 "$SNAP/tagobj-v1.12.json" "d['tagger']['date']" "2026-08-20T23:40:26Z" \
  'v1.12 was tagged 2026-08-20'
assert_json V13 "$SNAP/tags.json" "len([t for t in d if t['name'].startswith('v1.')])" "13" \
  'thirteen v1.x release tags exist, v1.0 through v1.12'
assert_json V14 "$SNAP/tags.json" "str(any(t['name'].startswith('v2') for t in d))" "False" \
  'no v2 tag exists: the action is on a stable v1 series'
assert_contains V15 "$SNAP/v1.12--CHANGELOG.md" '## [v1.12](https://github.com/openai/codex-action/tree/v1.12) (2026-08-20)' \
  'CHANGELOG.md dates v1.12 to 2026-08-20'
assert_contains V16 "$SNAP/v1.12--CHANGELOG.md" '## [v1.0](https://github.com/openai/codex-action/tree/v1.0) (2025-10-06)' \
  'CHANGELOG.md dates v1.0 to 2025-10-06, giving the cadence its span'
assert_contains V17 "$SNAP/v1.12--CHANGELOG.md" 'tighten what bots are allowed' \
  'the CHANGELOG records deliberate bot-handling work, at v1.8'

# ---------------------------------------------------------------------------
# M — the Marketplace question. The first-party action is NOT listed, and the
#     slug a maintainer would search for belongs to a third party.
# ---------------------------------------------------------------------------
assert_json M01 "$SNAP/issue-168.json" "d['state']+' '+str(d['comments'])" "open 0" \
  'vendor issue #168, which asks OpenAI to publish to the Marketplace, is open with zero comments'
assert_contains M02 "$SNAP/issue-168.json" "Publish codex-action to GitHub Marketplace" \
  'issue #168 is that Marketplace-publication request'
assert_file_equals M03 "$SNAP/marketplace-codex-exec-action.status" "404" \
  'the Marketplace slug the action name would produce, codex-exec-action, returns HTTP 404'
assert_file_equals M04 "$SNAP/marketplace-codex-action.status" "200" \
  'the slug codex-action DOES resolve, which is the confusion hazard'
assert_contains M05 "$SNAP/marketplace-codex-action.html" 'icoretech/codex-action' \
  'and it resolves to a THIRD-PARTY repository'
assert_absent M06 "$SNAP/marketplace-codex-action.html" 'openai/codex-action' \
  'that Marketplace page names openai/codex-action nowhere'
assert_absent M07 "$SNAP/marketplace-search-codex.html" 'marketplace/actions/codex-exec-action' \
  'a Marketplace search for "codex" lists no entry for the first-party action'
assert_contains M08 "$SNAP/marketplace-codex-code-review-actor.html" 'gersmann/codex-review-action' \
  'the "Codex Code Review & Actor" listing is a third-party action'
assert_contains M09 "$SNAP/marketplace-codex-reviewer.html" 'p2achAI/codex-reviewer' \
  'so is the "Codex Reviewer" listing'
assert_json M10 "$SNAP/repo-icoretech-codex-action.json" "d['owner']['login']" "icoretech" \
  'the Marketplace codex-action belongs to icoretech, not to openai'

# ---------------------------------------------------------------------------
# C — the credential. Exactly one credential input, and it is a SECRET by kind.
#     (HIGH question 2.)
# ---------------------------------------------------------------------------
assert_contains C01 "$SNAP/v1.12--action.yml" '  openai-api-key:' \
  'action.yml declares the openai-api-key input'
assert_absent C02 "$SNAP/v1.12--action.yml" 'azure-openai-api-key' \
  'action.yml declares NO separate Azure credential input'
assert_absent C03 "$SNAP/v1.12--action.yml" 'AZURE_OPENAI_API_KEY' \
  'and names AZURE_OPENAI_API_KEY nowhere'
assert_contains C04 "$SNAP/v1.12--action.yml" '  responses-api-endpoint:' \
  'an Azure-hosted deployment is reached by overriding responses-api-endpoint, reusing the same key input'
assert_contains C05 "$SNAP/v1.12--action.yml" 'https://example.openai.azure.com/openai/v1/responses' \
  'that input description gives an Azure endpoint as its own worked example'
assert_absent C06 "$SNAP/v1.12--action.yml" 'id-token' \
  'action.yml requests no OIDC id-token'
assert_absent C07 "$SNAP/v1.12--action.yml" 'ACTIONS_ID_TOKEN_REQUEST' \
  'and reads no OIDC request variable'
assert_absent C08 "$SNAP/v1.12--src_main.ts" 'getIDToken' \
  'the action source performs no OIDC token exchange'
assert_absent C09 "$SNAP/v1.12--src_main.ts" 'github-app-token-exchange' \
  'and mints no vendor App installation token, so R18\x27s pre-token window does not arise here'
assert_contains C10 "$SNAP/v1.12--action.yml" 'GITHUB_TOKEN: ${{ github.token }}' \
  "the only GitHub credential the action touches is the workflow's own github.token"

# ---------------------------------------------------------------------------
# G — the gate. `secrets` is unavailable in a job-level `if:` and available in
#     `jobs.<job_id>.env`, on GitHub's own documentation. (HIGH question 3.)
# ---------------------------------------------------------------------------
python3 - "$SNAP/gh-contexts.html" > "$WORK/contexts.txt" <<'PY'
import html, re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
text = re.sub(r"<[^>]+>", " ", text)
text = re.sub(r"\s+", " ", html.unescape(text))
for key in ("jobs.<job_id>.if", "jobs.<job_id>.env", "jobs.<job_id>.steps.if",
            "jobs.<job_id>.outputs.<output_id>"):
    match = re.search(re.escape(key) + r" ([^A-Z]*?)(?:None|always)", text)
    print(key, "=>", " ".join(match.group(1).split()) if match else "NOT FOUND")
PY
assert_contains G01 "$WORK/contexts.txt" 'jobs.<job_id>.if => github, needs, vars, inputs' \
  "GitHub's context table lists exactly github, needs, vars and inputs for a job-level if:, and not secrets"
assert_contains G02 "$WORK/contexts.txt" 'jobs.<job_id>.env => github, needs, strategy, matrix, vars, secrets, inputs' \
  'the same table lists secrets as available in a job-level env: block, which is what makes the relay possible'
assert_contains G03 "$WORK/contexts.txt" 'jobs.<job_id>.steps.if => github, needs, strategy, matrix, job, runner, env, vars, steps, inputs' \
  'secrets is unavailable in a STEP-level if: too, so the gate cannot simply move down one level'
assert_contains G04 "$WORK/contexts.txt" 'jobs.<job_id>.outputs.<output_id> => github, needs, strategy, matrix, job, runner, env, vars, secrets, steps, inputs' \
  'a job output MAY carry a secret-derived value, which is why the preflight publishes a literal string the runner will not mask'

# ---------------------------------------------------------------------------
# B — bots and actor trust, read in the action's own source AT THE v1.12 PIN.
#     (HIGH questions 4 and 6.)
# ---------------------------------------------------------------------------
assert_contains B01 "$SNAP/v1.12--action.yml" '"Allow runs triggered by trusted GitHub bot accounts (github-actions[bot]) to bypass the write-access check."' \
  'action.yml documents allow-bots as a bypass of the write-access check'
assert_contains B02 "$SNAP/v1.12--src_checkActorPermissions.ts" \
  'const TRUSTED_GITHUB_BOT_ACTORS = new Set(["github-actions[bot]"]);' \
  'the trusted-bot set holds exactly one login, github-actions[bot]'
assert_contains B03 "$SNAP/v1.12--src_checkActorPermissions.ts" \
  'if (allowBotActors && isTrustedGitHubBotActor(actor)) {' \
  'the [bot] shortcut is gated on allow-bots AND on that one-login set; it is NOT the unconditional endsWith("[bot]") approval R18 found in the Claude action'
assert_contains B04 "$SNAP/v1.12--src_checkActorPermissions.ts" \
  'const allowBotActors = options.allowBotActors ?? false;' \
  'and allow-bots defaults to false, so by default no bot is shortcut-approved'
assert_contains B05 "$SNAP/v1.12--src_checkActorPermissions.ts" \
  'if (permission === "admin" || permission === "write" || permission === "maintain") {' \
  "the action's internal check is a WRITE-PERMISSION test, so any bot holding write still passes it"
assert_contains B06 "$SNAP/v1.12--src_checkActorPermissions.ts" \
  'const actor = options.actor ?? process.env.GITHUB_ACTOR;' \
  'it checks the RUN ACTOR, never the comment author, so the comment-author guard must live in the workflow'
assert_contains B07 "$SNAP/v1.12--src_checkActorPermissions.ts" \
  "core.info(\"allow-users='*' specified; allowing all users to proceed.\");" \
  'allow-users: "*" approves every actor, neutralising the only internal actor control'
assert_contains B08 "$SNAP/v1.12--src_main.ts" 'throw new Error(message);' \
  'a rejected actor THROWS, so the model job fails red rather than skipping'
assert_contains B09 "$SNAP/v1.12--src_main.ts" \
  "const message = \`Actor '\${result.actor}' is not permitted to run this action: \${result.reason}\`;" \
  'and the thrown message is the observable signal P03 will see for that failure'
assert_contains B10 "$SNAP/v1.12--docs_security.md" \
  'By default, `openai/codex-action` can only be run by a user who has _write_ access to your repository.' \
  'the vendor documents that internal write check, which this template cannot remove'

# ---------------------------------------------------------------------------
# S — the action's step ORDER and its capabilities. (HIGH questions 4 and 5,
#     and the MEDIUM trigger-vocabulary question.)
# ---------------------------------------------------------------------------
python3 - "$SNAP/v1.12--action.yml" > "$WORK/steporder.txt" <<'PY'
import re, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
wanted = ["Check repository write access", "Install Codex CLI",
          "Start Responses API proxy", "Run codex exec"]
seen = []
for number, line in enumerate(lines, 1):
    match = re.match(r'\s*- name: (.+)$', line)
    if match and match.group(1) in wanted:
        seen.append((match.group(1), number))
print("ORDER " + " < ".join("%s@%d" % pair for pair in seen))
print("MONOTONIC %s" % ([name for name, _ in seen] == wanted))
PY
assert_contains S01 "$WORK/steporder.txt" 'MONOTONIC True' \
  'the write-access check runs BEFORE the CLI install, before the credential-bearing proxy starts and before codex exec'
assert_contains S02 "$WORK/steporder.txt" 'Check repository write access@149 < Install Codex CLI@163' \
  'the exact line numbers of that ordering at the v1.12 pin'
assert_contains S03 "$SNAP/v1.12--action.yml" \
  "if: \${{ inputs.prompt != '' || inputs['prompt-file'] != '' }}" \
  'the codex exec step requires a prompt, so the action has NO interactive or mention-listening mode'
assert_contains S04 "$SNAP/v1.12--action.yml" '`prompt` or `prompt-file` must be provided.' \
  'action.yml states the same requirement in its own input description'
assert_absent S05 "$SNAP/v1.12--action.yml" 'createComment' \
  'nothing in action.yml posts a comment'
assert_absent S06 "$SNAP/v1.12--src_main.ts" 'createComment' \
  'nothing in the action source posts one either, so a separate poster job is FORCED rather than chosen'
assert_contains S07 "$SNAP/v1.12--action.yml" "  final-message:" \
  'the action publishes exactly one output, final-message, which is what the poster job consumes'
assert_file_equals S08 "$SNAP/v1.12--examples-listing.txt" \
  "test-sandbox-protections.ymlunprivileged-user.yml" \
  'the vendor ships exactly two examples and NEITHER is comment-triggered, so the assistant lane has no vendor reference to copy'
assert_absent S09 "$SNAP/v1.12--examples-listing.txt" 'review' \
  'and no vendor example is a pull-request review lane either'
assert_file_equals S10 "$SNAP/v1.12--src-listing.txt" \
  "checkActorPermissions.tscheckOutput.tsdropSudo.tslinuxCredentials.tsmain.tsreadServerInfo.tsrunCodexExec.tswriteProxyConfig.ts" \
  'the action source is eight files, so the absence of any comment-posting or token-exchange code above is a complete census, not a sample'

# ---------------------------------------------------------------------------
# P — the CLI pin. One input pins TWO npm packages, so version parity matters.
# ---------------------------------------------------------------------------
assert_contains P01 "$SNAP/v1.12--action.yml" 'run: npm install -g "@openai/codex@${CODEX_VERSION}"' \
  'the CLI is installed from npm at whatever the codex-version input holds'
assert_contains P02 "$SNAP/v1.12--action.yml" 'run: npm install -g "@openai/codex-responses-api-proxy@${CODEX_VERSION}"' \
  'the SAME input also pins the Responses API proxy package'
assert_json P03 "$SNAP/npm-openai-codex.pruned.json" "d['dist-tags']['latest']" "0.154.0" \
  '@openai/codex dist-tags.latest is 0.154.0'
assert_json P04 "$SNAP/npm-openai-codex.pruned.json" "d['time']['0.154.0']" "2026-09-09T22:40:10.746Z" \
  'and 0.154.0 was published 2026-09-09'
assert_json P05 "$SNAP/npm-openai-codex-responses-api-proxy.pruned.json" "d['dist-tags']['latest']" "0.154.0" \
  'the proxy package is at the SAME version, so one pin of 0.154.0 resolves both installs'
assert_json P06 "$SNAP/npm-openai-codex-responses-api-proxy.pruned.json" "str('0.154.0' in d['versions'])" "True" \
  'the proxy genuinely publishes a 0.154.0 version, which the shared pin requires'
assert_json P07 "$SNAP/npm-openai-codex.pruned.json" "d['license']" "Apache-2.0" \
  "the CLI's own licence (metadata only; gate 1 is inapplicable by owner ruling)"
assert_json P08 "$SNAP/issue-171.json" "d['state']+' '+str(d['comments'])" "open 0" \
  'vendor issue #171 — a pinned action still installs an unpinned CLI — is open and unanswered'
assert_contains P09 "$SNAP/issue-171.json" "codex-version defaults to empty" \
  'issue #171 is that unpinned-CLI defect, which is why the explicit pin is not optional'
assert_contains P10 "$SNAP/v1.12--README.md" 'Permission profiles are beta and require Codex CLI `0.138.0` or' \
  'permission profiles are BETA and carry a CLI floor of 0.138.0, which the 0.154.0 pin clears'

# ---------------------------------------------------------------------------
# A — advisories and maintenance figures.
# ---------------------------------------------------------------------------
assert_json A01 "$SNAP/adv-repo-codex-action.json" "len(d)" "0" \
  'the action repository publishes no security advisory of its own'
assert_json A02 "$SNAP/adv-actions-ecosystem.json" "len([a for a in d if 'codex' in json.dumps(a).lower()])" "0" \
  'no advisory in the GitHub actions ecosystem names codex'
assert_json A03 "$SNAP/adv-npm-openai-codex.json" "len(d)" "2" \
  'two npm advisories exist against the CLI the action installs'
assert_json A04 "$SNAP/adv-npm-openai-codex.json" \
  "';'.join(sorted(a['ghsa_id']+'|'+a['severity']+'|'+a['vulnerabilities'][0]['vulnerable_version_range'] for a in d))" \
  "GHSA-w5fx-fh39-j5rw|high|>= 0.2.0, <= 0.38.0;GHSA-xrxf-jgv3-qmrm|critical|<= 0.23.0" \
  'and both advisory ranges end far below the recommended 0.154.0 pin'
assert_json A05 "$SNAP/search-open-issues.json" "d['total_count']" "37" \
  'open ISSUES, read from the search endpoint as the prompt requires'
assert_json A06 "$SNAP/search-open-prs.json" "d['total_count']" "43" \
  'open PULL REQUESTS, the other half of the conflated figure'
assert_json A07 "$SNAP/repo-codex-action.json" "d['open_issues_count']" "80" \
  'open_issues_count reads 80 = 37 + 43, which is why the prompt forbids using it'
assert_json A08 "$SNAP/repo-codex-action.json" "d['pushed_at']" "2026-09-11T00:26:35Z" \
  'main was last pushed 2026-09-11, AFTER the v1.12 tag: main carries unreleased commits, so every source read above is at the pin'
assert_json A09 "$SNAP/issue-175.json" "d['state']" "open" \
  'vendor issue #175 — model output carrying workflow commands fails the action — is open'
assert_json A10 "$SNAP/issue-169.json" "d['state']" "open" \
  'vendor issue #169 — the CLI hangs after final output — is open'
assert_json A11 "$SNAP/issue-172.json" "d['state']" "open" \
  'vendor issue #172 — a PR review hangs forever — is open'
assert_json A12 "$SNAP/issue-160.json" "d['state']" "open" \
  'vendor issue #160 — drop-sudo breaks service sockets — is open'
assert_json A13 "$SNAP/issue-169.json" "d['title']" \
  "Codex CLI 0.150.1 still hangs after final output" \
  'the hang report names a CLI version BELOW the recommended 0.154.0 pin, so it is a reliability risk rather than a defect in the pinned build'
assert_json A14 "$SNAP/issue-175.json" \
  "';'.join(sorted({a['author_association'] for a in [d]}))" "NONE" \
  'every vendor issue cited here was opened by a non-maintainer, which is the issue-triage deficiency the maintenance verdict records'

# ---------------------------------------------------------------------------
# D — the vendor's own security guidance, quoted verbatim from the pin.
#     (HIGH question 5, the trusted-author residual.)
# ---------------------------------------------------------------------------
assert_contains D01 "$SNAP/v1.12--docs_security.md" \
  'these same sources can also be used as vehicles for _prompt injection_' \
  'the vendor documents prompt injection as a property of the input surface, not as a defect'
assert_contains D02 "$SNAP/v1.12--docs_security.md" \
  'it is fairly easy to hide information in a pull request body using an HTML comment' \
  'the pull-request body is named as one of the four injection vectors'
assert_contains D03 "$SNAP/v1.12--docs_security.md" \
  'should be considered part of the untrusted input surface' \
  'repository instruction files under pull-request control are untrusted, which is why the checkout is of the BASE branch'
assert_contains D04 "$SNAP/v1.12--docs_security.md" \
  'Instead, pass those values through `env:` and quote the shell variables that consume them' \
  'the shell-injection guidance the poster job and the request packet both follow'
assert_contains D05 "$SNAP/v1.12--docs_security.md" \
  'it is possible to take the output of the `openai/codex-action` and then pass it along to a new job' \
  'the vendor recommends the model-job / poster-job split this decision adopts'
assert_contains D06 "$SNAP/v1.12--docs_security.md" \
  'you might find yourself the target of API key abuse' \
  'the vendor names the abuse that allow-users: "*" invites'
assert_contains D07 "$SNAP/v1.12--README.md" \
  'Linux/macOS**: All options for `safety-strategy` are supported.' \
  'fitness gate 4: Linux and macOS both support every safety strategy'
assert_contains D08 "$SNAP/v1.12--action.yml" \
  'Specify one of the following options (on Windows, the only supported option is `unsafe`):' \
  'Windows is noted as needing safety-strategy: unsafe, and is not required by target-os-matrix'
assert_contains D09 "$SNAP/v1.12--README.md" \
  'permissions:' \
  "the README's own worked example states per-job permissions"
assert_contains D10 "$SNAP/v1.12--README.md" \
  'While Codex cloud offers a [powerful code review tool]' \
  'the README itself points at the hosted connector as the alternative to building this lane'

# ---------------------------------------------------------------------------
# X — practice evidence, read from the adopters' own committed workflow files.
# ---------------------------------------------------------------------------
assert_contains X01 "$SNAP/adopter-trailofbits-codex-review.yml" \
  'uses: openai/codex-action@86365089eb2b84e0a8fb0717b304f8bdcb13b20e # v1' \
  'trailofbits/coop pins the action to the same commit this decision resolved for v1.12'
assert_contains X02 "$SNAP/adopter-trailofbits-codex-review.yml" \
  "contains(fromJSON('[\"OWNER\",\"MEMBER\",\"COLLABORATOR\"]'), github.event.comment.author_association) &&" \
  'and reaches the same author_association prefilter independently of R18'
assert_contains X03 "$SNAP/adopter-trailofbits-codex-review.yml" 'permission-profile: :read-only' \
  'it runs the model under the :read-only profile'
assert_contains X04 "$SNAP/adopter-trailofbits-codex-review.yml" 'safety-strategy: drop-sudo' \
  'and keeps the drop-sudo safety strategy'
assert_contains X05 "$SNAP/adopter-trailofbits-codex-review.yml" \
  'pull-requests: write # No model credential; only posts the completed review.' \
  'it splits the poster job out with no model credential, in its own words'
assert_contains X06 "$SNAP/adopter-trailofbits-codex-review.yml" 'UNTRUSTED PR DATA' \
  'it labels the untrusted packet explicitly, which the assistant fixture mirrors'
assert_contains X07 "$SNAP/adopter-supabase-ai-review-README.md" 'which re-reviewed a PR 30-40 times' \
  'the two-vendor comment-volume evidence: automatic per-push review produced 30-40 rounds on one pull request'
assert_contains X08 "$SNAP/adopter-supabase-ai-review-README.md" 'burning reviewer attention on' \
  'and the cost that adopter states is reviewer attention, not runner minutes'
assert_contains X09 "$SNAP/adopter-supabase-ai-review-README.md" \
  "External contributors' PRs are never reviewed automatically; a maintainer" \
  'an adopter states and accepts the same fork-guard tradeoff this decision takes'
assert_contains X10 "$SNAP/adopter-supabase-ai-review-README.md" 'The Codex GitHub App' \
  'and records that the hosted connector must be disabled by hand: it is not a file an adopter can delete'
assert_contains X11 "$SNAP/adopter-supabase-ai-review-README.md" \
  'Authorization for `/ai-review` requires repository write, not org' \
  'that adopter chose a WRITE test where this owner chose association: a real divergence, recorded rather than smoothed over'
assert_contains X12 "$SNAP/adopter-uv-update-issue-context.yml" 'codex-version: "0.147.0"' \
  'astral-sh/uv pins the CLI explicitly, which is the practice this decision follows'
assert_contains X13 "$SNAP/adopter-uv-update-issue-context.yml" 'safety-strategy: drop-sudo' \
  'and also keeps drop-sudo'
python3 - "$SNAP/connector-github.html" > "$WORK/connector.txt" <<'CONNECTOR'
import html, re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
text = re.sub(r"<[^>]+>", " ", text)
print(re.sub(r"\s+", " ", html.unescape(text)))
CONNECTOR
assert_contains X14 "$WORK/connector.txt" 'request reviews with @codex review and @codex security review' \
  "the vendor's HOSTED connector claims the @codex token, which is why this lane uses /codex instead"
assert_contains X15 "$WORK/connector.txt" 'Mention @codex in your pull request to ask questions or start a task' \
  'and claims the bare @codex mention for assistant-style requests too, so the collision would cover both lanes'

# ---------------------------------------------------------------------------
# L — actionlint over the committed fixtures. The three controls are what make
#     the two clean results evidence rather than decoration.
# ---------------------------------------------------------------------------
if command -v actionlint > /dev/null 2>&1; then
  LINTDIR="$WORK/.github/workflows"
  mkdir -p "$LINTDIR"
  cp "$EVIDENCE_DIR"/candidate-codex-code-review.yml \
    "$EVIDENCE_DIR"/candidate-codex.yml \
    "$EVIDENCE_DIR"/control-secret-in-job-if.yml \
    "$EVIDENCE_DIR"/control-negative-gate.yml \
    "$EVIDENCE_DIR"/control-misspelled-output.yml "$LINTDIR/"
  lint_one() { # lint_one <basename> <outfile> -> prints the exit status
    local rc=0
    (cd "$WORK" && actionlint -no-color -oneline ".github/workflows/$1" > "$2" 2>&1) || rc=$?
    echo "$rc"
  }

  rc="$(lint_one candidate-codex-code-review.yml "$WORK/l1.out")"
  if [ "$rc" = "0" ] && [ ! -s "$WORK/l1.out" ]; then
    pass L01 "the review-lane fixture lints clean [actionlint exit=0, 0 diagnostics]"
  else
    sed 's/^/    /' "$WORK/l1.out"
    fail L01 "the review-lane fixture did not lint clean [exit=$rc]"
  fi

  rc="$(lint_one candidate-codex.yml "$WORK/l2.out")"
  if [ "$rc" = "0" ] && [ ! -s "$WORK/l2.out" ]; then
    pass L02 "the assistant-lane fixture lints clean [actionlint exit=0, 0 diagnostics]"
  else
    sed 's/^/    /' "$WORK/l2.out"
    fail L02 "the assistant-lane fixture did not lint clean [exit=$rc]"
  fi

  rc="$(lint_one control-secret-in-job-if.yml "$WORK/l3.out")"
  if [ "$rc" = "1" ]; then
    assert_contains L03 "$WORK/l3.out" \
      'context "secrets" is not allowed here. available contexts are "github", "inputs", "needs", "vars".' \
      'NEGATIVE CONTROL: a job-level if: reading secrets is REJECTED, and the diagnostic carries the platform rule'
  else
    sed 's/^/    /' "$WORK/l3.out"
    fail L03 "the secrets-in-job-if negative control did not fail as required [exit=$rc]"
  fi

  rc="$(lint_one control-misspelled-output.yml "$WORK/l4.out")"
  if [ "$rc" = "1" ]; then
    assert_contains L04 "$WORK/l4.out" \
      'property "credentail" is not defined in object type {credential: string}' \
      'NEGATIVE CONTROL: actionlint TYPE-CHECKS the needs relay, so the fixtures clean lint covers the wiring and not only the syntax'
  else
    sed 's/^/    /' "$WORK/l4.out"
    fail L04 "the misspelled-output negative control did not fail as required [exit=$rc]"
  fi

  rc="$(lint_one control-negative-gate.yml "$WORK/l5.out")"
  if [ "$rc" = "0" ] && [ ! -s "$WORK/l5.out" ]; then
    pass L05 "LIMIT CONTROL: the NEGATIVE credential gate lints clean too, so the linter does not establish the gate polarity; the argument for the positive form is the empty-output semantics of a skipped dependency, which no check here executed"
  else
    sed 's/^/    /' "$WORK/l5.out"
    fail L05 "the negative-gate limit control behaved unexpectedly [exit=$rc]"
  fi
else
  skip L01 "actionlint is not installed: the review-lane fixture was not linted"
  skip L02 "actionlint is not installed: the assistant-lane fixture was not linted"
  skip L03 "actionlint is not installed: the secrets-in-job-if negative control was not run"
  skip L04 "actionlint is not installed: the misspelled-output negative control was not run"
  skip L05 "actionlint is not installed: the negative-gate limit control was not run"
fi

# ---------------------------------------------------------------------------
# F — the fixtures embody exactly what the decision recommends. FR* is the
#     review lane, FA* the assistant lane.
# ---------------------------------------------------------------------------
check_lane() { # check_lane <id-prefix> <fixture>
  local id="$1" f="$EVIDENCE_DIR/$2"
  assert_absent "${id}01" "$f" "outputs.credential != " \
    "$2 gates POSITIVELY: no '!=' form of the credential gate appears"
  assert_contains "${id}02" "$f" "if: needs.credential-preflight.outputs.credential == 'present'" \
    "$2 gates the model job on the preflight output through needs"
  assert_contains "${id}03" "$f" 'permissions: {}' \
    "$2 denies every permission at the top level and on the preflight job"
  assert_contains "${id}04" "$f" "github.event.sender.type != 'Bot'" \
    "$2 rejects a bot-initiated run"
  assert_contains "${id}05" "$f" 'permission-profile: ":read-only"' \
    "$2 runs the model under the :read-only profile"
  assert_contains "${id}06" "$f" 'safety-strategy: drop-sudo' \
    "$2 keeps the drop-sudo safety strategy"
  assert_contains "${id}07" "$f" 'codex-version: "0.154.0"' \
    "$2 pins the Codex CLI explicitly"
  assert_contains "${id}08" "$f" 'uses: openai/codex-action@v1.12' \
    "$2 names the action and the version evaluated; the pin FORM is R20's"
  assert_absent "${id}09" "$f" 'id-token' \
    "$2 requests no OIDC token on any job"
  assert_absent "${id}10" "$f" 'ENABLE_' \
    "$2 carries no enable variable of any kind, as the owner requires"
  assert_absent "${id}11" "$f" 'allow-users' \
    "$2 does not widen the action's internal actor check"
  assert_contains "${id}12" "$f" 'OPENAI_API_KEY' \
    "$2 names the secret whose absence it prints about"
  assert_contains "${id}13" "$f" 'GITHUB_STEP_SUMMARY' \
    "$2 prints the missing-key message to the run summary as well as to a ::notice annotation"
  assert_contains "${id}14" "$f" 'timeout-minutes: 20' \
    "$2 bounds the model job, against the three open hang issues #160, #169 and #172"
  assert_contains "${id}15" "$f" 'persist-credentials: false' \
    "$2 checks out without leaving a usable git credential in the tree"
  assert_absent "${id}16" "$f" 'pull_request_target' \
    "$2 does not use pull_request_target"
}
check_lane FR candidate-codex-code-review.yml
check_lane FA candidate-codex.yml
assert_contains FR22 "$EVIDENCE_DIR/candidate-codex-code-review.yml" \
  'echo "OPENAI_API_KEY is configured, so Codex code review will run on this pull request."' \
  'the review lane prints on the PRESENT branch too, which is the only channel reaching an adopter whose repository already carried the key'
assert_contains FA26 "$EVIDENCE_DIR/candidate-codex.yml" \
  'echo "OPENAI_API_KEY is configured, so the Codex assistant will answer this comment."' \
  'and so does the assistant lane'
assert_contains D11 "$SNAP/v1.12--docs_security.md" \
  'the combination of read-only access to the filesystem and `sudo` can be used to expose your `OPENAI_API_KEY`' \
  'the vendor documents the exfiltration path that rejects architecture C, the bare CLI in a run: step'
assert_contains D12 "$SNAP/v1.12--docs_security.md" \
  'Be sure to use either `drop-sudo` or `unprivileged-user` to ensure it stays secret!' \
  'and names the safety strategy that closes it, which both lanes keep'
assert_contains X16 "$SNAP/adopter-supabase-ai-review-README.md" \
  "the comment's first line, trimmed, must be" \
  'that adopter matches its command on the first line exactly, the practice the /codex startsWith form follows'
assert_contains FR17 "$EVIDENCE_DIR/candidate-codex-code-review.yml" \
  'github.event.pull_request.head.repo.full_name == github.repository' \
  'the review lane carries the fork guard'
assert_contains FR18 "$EVIDENCE_DIR/candidate-codex-code-review.yml" \
  'github.event.pull_request.draft == false' \
  'the review lane carries the draft clause R18 added at its revision 3'
assert_contains FR19 "$EVIDENCE_DIR/candidate-codex-code-review.yml" \
  "github.event.pull_request.user.type != 'Bot'" \
  "the review lane also rejects a bot-authored pull request, not only a bot initiator"
assert_absent FR20 "$EVIDENCE_DIR/candidate-codex-code-review.yml" 'synchronize' \
  'the review lane does NOT trigger on synchronize, which is the per-push re-review X07 measured at 30-40 rounds'
assert_contains FR21 "$EVIDENCE_DIR/candidate-codex-code-review.yml" \
  'ref: ${{ github.event.pull_request.base.sha }}' \
  "the review lane's working tree is the TRUSTED base, so the AGENTS.md the CLI loads is not the contributor's"
assert_contains FA17 "$EVIDENCE_DIR/candidate-codex.yml" \
  "startsWith(github.event.comment.body, '/codex')" \
  'the assistant lane matches the command at the START of the comment body'
assert_absent FA18 "$EVIDENCE_DIR/candidate-codex.yml" \
  "contains(github.event.comment.body, '@codex')" \
  'and never uses the contains() form, which re-fires on quoted text'
"$GREP" -v '^[[:space:]]*#' "$EVIDENCE_DIR/candidate-codex.yml" > "$WORK/assistant-nocomments.yml"
assert_absent FA19 "$WORK/assistant-nocomments.yml" '@claude' \
  "no CONFIGURATION line of the assistant lane names @claude, so it cannot collide with R18's token; the single occurrence in the file is the comment explaining the choice, and comments are stripped before this count"
assert_absent FA25 "$WORK/assistant-nocomments.yml" '@codex' \
  'and no configuration line names @codex either, so it cannot collide with the hosted connector'
assert_contains FA20 "$EVIDENCE_DIR/candidate-codex.yml" \
  "contains(fromJSON('[\"OWNER\",\"MEMBER\",\"COLLABORATOR\"]'), github.event.comment.author_association)" \
  'the assistant lane carries the author_association prefilter, in the exact shape R18 clause (d) specifies'
assert_absent FA21 "$EVIDENCE_DIR/candidate-codex.yml" 'contents: write' \
  'and holds no write capability over repository contents'
assert_contains FA22 "$EVIDENCE_DIR/candidate-codex.yml" \
  "github.event.comment.user.type != 'Bot'" \
  "the assistant lane checks the comment AUTHOR's type as well as the run initiator's"
assert_contains FA23 "$EVIDENCE_DIR/candidate-codex.yml" \
  "github.event.issue.pull_request != null" \
  'and scopes issue_comment to pull-request conversations, so a plain issue comment starts no run'
assert_contains FA24 "$EVIDENCE_DIR/candidate-codex.yml" 'UNTRUSTED REQUEST DATA' \
  'the assistant lane hands the comment to the model as labelled data, never as instructions'

# ---------------------------------------------------------------------------
# N — this run's own engine record, for `## Engines`.
# ---------------------------------------------------------------------------
for f in opus.md doxa.md doxa.normalized.md doxa-openai.normalized.md \
  doxa-perplexity.normalized.md doxa-gemini.normalized.md; do
  if [ -f "$RUN_DIR/raw/$f" ]; then
    echo "SHA256 raw/$f $(sha_of "$RUN_DIR/raw/$f")"
  else
    echo "SHA256 raw/$f MISSING"
  fi
done
assert_contains N01 "$RUN_DIR/doxa/normalization.json" '"shape": "FAIL: answer: bundle member' \
  'the perplexity twin fails its own per-provider shape check, as the normalizer recorded'
assert_contains N02 "$RUN_DIR/doxa/normalization.json" \
  "missing fields: ['Compatibility', 'Parameters', 'Migration implications', 'Validation strategy', 'Confidence & re-verify trigger']" \
  'five top-level fields are absent from the perplexity twin'
assert_contains N03 "$RUN_DIR/doxa/normalization.json" 'demoted to bold text' \
  'both perplexity members were demoted by the merge, so neither survives as a member of the merged bundle twin'
assert_contains N04 "$RUN_DIR/doxa/normalization.json" \
  "member 'Codex comment‑triggered assistant workflow (F362)' incomplete (H5 fields present: ['Landscape', 'Principles and implementation', 'Dominant choice', 'Qualified shortlist', 'Excluded by gate'])" \
  "perplexity's F362 member stops after five fields, which is why its F362 material is weighed as incomplete"
assert_contains N05 "$RUN_DIR/doxa/normalization.json" '"shape": "OK: validation passed"' \
  'the merged bundle twin and the openai and gemini twins pass the shape check'
assert_contains N06 "$RUN_DIR/doxa/normalization.json" 'research-20260917-081418-d364fa415a4a4224' \
  'the Doxa operation identifier this run consumed'
if [ -e "$RUN_DIR/raw/codex.md" ]; then
  fail N07 "a codex raw report exists, which would contradict the recorded W1-CODEX deferral"
else
  pass N07 "no codex raw report exists in this run: the Codex leg is the controller's deferral under owner ruling W1-CODEX, not a failed engine"
fi

echo
echo "passed=$PASSED failures=$FAILURES skipped=$SKIPPED total=$((PASSED + FAILURES + SKIPPED))"
if [ "$FAILURES" -ne 0 ]; then
  exit 1
fi
exit 0
