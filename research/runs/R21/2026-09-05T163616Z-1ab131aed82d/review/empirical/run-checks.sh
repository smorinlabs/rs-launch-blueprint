#!/usr/bin/env bash
# R21 contributors-bot-credential-source — synthesizer empirical check.
#
# VERIFIES claims made by the two raw reports. It does NOT implement the
# recommendation and it performs no mutation of any kind:
#   * no credential is created, read or used;
#   * no GitHub App is registered or installed;
#   * no pull request is opened;
#   * no GitHub API endpoint is called with any token (the only network calls
#     are unauthenticated GETs of four public docs.github.com pages).
# The pinned source repositories are read through their programme pins with
# `git show <pin>:<path>`, never from a working tree.
#
# Exit status: 0 when every assertion holds, 1 otherwise.

set -uo pipefail

PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
ACTION_TAG=v1.3.9
ACTION_SHA=3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1

PY_REPO=${PY_REPO:-$HOME/c/py-launch-blueprint}
TS_REPO=${TS_REPO:-$HOME/c/ts-launch-blueprint}
ACTION_REPO=${ACTION_REPO:-$HOME/c/contributors-please-action}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); echo "  [ok]   $*"; }
bad()  { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }
case_() { echo; echo "=== $* ==="; }

# assert_contains <label> <file> <fixed-string>
assert_contains() {
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (string not found: $3)"; fi
}
# assert_absent <label> <file> <ERE>
assert_absent_re() {
  if grep -qE -- "$3" "$2"; then bad "$1 (pattern unexpectedly present: $3)"; else ok "$1"; fi
}

echo "R21 empirical check — synthesizer"
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

case_ "00 toolchain and host"
echo "rustc:  $(rustc --version 2>&1)"
echo "cargo:  $(cargo --version 2>&1)"
echo "os:     $(uname -srm)  ($(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) build $(sw_vers -buildVersion 2>/dev/null))"
echo "git:    $(git --version)"
echo "curl:   $(curl --version | head -1)"
echo "python3:$(python3 --version 2>&1)"
echo "note: no Rust is compiled by this item; the toolchain is recorded per the role contract."

# ---------------------------------------------------------------------------
case_ "01 action tag -> commit, resolved locally (no API call)"
TAG_SHA=$(git -C "$ACTION_REPO" rev-parse "${ACTION_TAG}^{commit}" 2>&1)
echo "git -C $ACTION_REPO rev-parse ${ACTION_TAG}^{commit} => $TAG_SHA"
if [ "$TAG_SHA" = "$ACTION_SHA" ]; then
  ok "tag $ACTION_TAG resolves to $ACTION_SHA"
else
  bad "tag $ACTION_TAG resolved to $TAG_SHA, expected $ACTION_SHA"
fi
echo "clone HEAD: $(git -C "$ACTION_REPO" rev-parse HEAD)"

# ---------------------------------------------------------------------------
case_ "02 py-launch-blueprint workflow at pin $PY_PIN"
git -C "$PY_REPO" show "$PY_PIN:.github/workflows/update-contributors.yml" > "$WORK/py-wf.yml" 2>&1
grep -n 'app-id:\|private-key:\|pat:\|uses: smorinlabs\|mode:\|runs-on:\|commit-message:' "$WORK/py-wf.yml"
assert_contains "py sources the fallback from a dedicated repo secret" "$WORK/py-wf.yml" 'pat: ${{ secrets.CONTRIBUTORS_PLEASE_PAT }}'
assert_contains "py passes App credentials alongside it" "$WORK/py-wf.yml" 'app-id: ${{ secrets.CONTRIBUTORS_PLEASE_CLIENT_ID }}'
echo "--- py's own [skip ci] rationale comment, verbatim ---"
sed -n '39,44p' "$WORK/py-wf.yml"

# ---------------------------------------------------------------------------
case_ "03 ts-launch-blueprint workflow at pin $TS_PIN"
git -C "$TS_REPO" show "$TS_PIN:.github/workflows/update-contributors.yml" > "$WORK/ts-wf.yml" 2>&1
grep -n 'app-id:\|private-key:\|pat:\|uses: smorinlabs\|mode:\|runs-on:' "$WORK/ts-wf.yml"
assert_contains "ts sources the fallback from the ambient GITHUB_TOKEN" "$WORK/ts-wf.yml" 'pat: ${{ secrets.GITHUB_TOKEN }}'
echo "--- ts's own zero-setup claim, verbatim ---"
sed -n '40,46p' "$WORK/ts-wf.yml"

# ---------------------------------------------------------------------------
case_ "04 action credential resolution, source at $ACTION_SHA"
git -C "$ACTION_REPO" show "$ACTION_SHA:src/index.ts" > "$WORK/index.ts" 2>&1
echo "--- fail-fast when neither credential is supplied ---"
grep -n 'Provide either app-id + private-key, or pat\.' "$WORK/index.ts"
echo "--- App branch is taken whenever app-id AND private-key are both non-empty ---"
sed -n '394,400p' "$WORK/index.ts" | grep -n '' | sed 's/^/    /'
grep -n 'if (appId && privateKey) {' "$WORK/index.ts"
echo "--- the PAT path resolves identity through the bare /user endpoint and throws on a non-ok response ---"
sed -n '426,442p' "$WORK/index.ts" | grep -n '' | sed 's/^/    /'
grep -n 'apiUrl.replace(/\\/\$/, "")}/user' "$WORK/index.ts"
grep -n 'GitHub token identity lookup failed' "$WORK/index.ts"
assert_contains "PAT path calls <apiUrl>/user with a Bearer header" "$WORK/index.ts" '/user`, {'
assert_contains "PAT path throws on a non-ok identity response" "$WORK/index.ts" 'GitHub token identity lookup failed: ${response.status}'
assert_contains "fail-fast message is as the raws quote it" "$WORK/index.ts" 'Provide either app-id + private-key, or pat.'
assert_contains "App branch precedes the PAT branch" "$WORK/index.ts" 'if (appId && privateKey) {'

echo "--- by contrast the App path resolves its committer through /users/{username} ---"
git -C "$ACTION_REPO" show "$ACTION_SHA:src/app-token.ts" > "$WORK/app-token.ts" 2>&1
grep -n 'GET /users/{username}' "$WORK/app-token.ts"
assert_contains "App path uses GET /users/{username}" "$WORK/app-token.ts" 'GET /users/{username}'

# ---------------------------------------------------------------------------
case_ "05 action inputs, outputs and documented precedence at $ACTION_SHA"
git -C "$ACTION_REPO" show "$ACTION_SHA:action.yml" > "$WORK/action.yml" 2>&1
grep -n -A3 '^  pat:' "$WORK/action.yml"
grep -n -A1 '^  token-source:\|^  pr-opened:\|^  pr-url:' "$WORK/action.yml"
assert_contains "pat is declared optional with an empty default" "$WORK/action.yml" 'Personal access token fallback. Used when App credentials are absent.'
assert_contains "the action exposes a token-source output" "$WORK/action.yml" 'token-source:'
git -C "$ACTION_REPO" show "$ACTION_SHA:README.md" > "$WORK/README.md" 2>&1
echo "--- documented precedence and pull-request mode ---"
sed -n '45,53p' "$WORK/README.md"
assert_contains "README documents App-over-PAT precedence" "$WORK/README.md" 'App credentials are preferred when both App and PAT inputs are present.'

# ---------------------------------------------------------------------------
case_ "06 what the action's own e2e suite CONFIGURES for pat: (at $ACTION_SHA)"
git -C "$ACTION_REPO" show "$ACTION_SHA:.github/workflows/e2e.yml" > "$WORK/e2e.yml" 2>&1
grep -n 'pat:' "$WORK/e2e.yml"
assert_absent_re "no e2e lane configures secrets.GITHUB_TOKEN as pat:" "$WORK/e2e.yml" 'pat:.*secrets\.GITHUB_TOKEN'
echo "NOTE: this shows what the file CONFIGURES. Whether any lane actually ran, and"
echo "      with what result, depends on that repository's secrets and run history,"
echo "      which cannot be read without an authenticated token. Not established here."

# ---------------------------------------------------------------------------
case_ "07 GitHub Docs — endpoints available to installation access tokens"
DOC1="https://docs.github.com/en/rest/authentication/endpoints-available-for-github-app-installation-access-tokens?apiVersion=2022-11-28"
cat > "$WORK/extract.py" <<'PYEOF'
import re, html, sys
s = open(sys.argv[1], encoding='utf-8').read()
s = re.sub(r'(?is)<(script|style)[^>]*>.*?</\1>', ' ', s)
t = html.unescape(re.sub(r'(?s)<[^>]+>', ' ', s))
sys.stdout.write(re.sub(r'[ \t]+', ' ', t))
PYEOF
fetch() { # fetch <url> <out-basename>
  local code
  code=$(curl -sS -L --max-time 90 -o "$WORK/$2.html" -w '%{http_code}' "$1")
  echo "GET $1 -> HTTP $code, $(wc -c < "$WORK/$2.html" | tr -d ' ') bytes (unauthenticated; no Authorization header)"
  python3 "$WORK/extract.py" "$WORK/$2.html" > "$WORK/$2.txt"
  [ "$code" = "200" ]
}
if fetch "$DOC1" doc1; then ok "installation-token endpoint list retrieved"; else bad "could not retrieve $DOC1"; fi
echo "--- every '/user...' endpoint the page lists ---"
grep -oE 'GET /user[A-Za-z0-9_{}/-]*' "$WORK/doc1.txt" | sort -u
echo "--- anchored search for the BARE 'GET /user' entry the action's PAT path calls ---"
if grep -qE 'GET /user([^A-Za-z0-9_{}/-]|$)' "$WORK/doc1.txt"; then
  bad "bare 'GET /user' IS listed for installation access tokens"
else
  ok "bare 'GET /user' is NOT listed among the endpoints available to installation access tokens"
fi

# ---------------------------------------------------------------------------
case_ "08 GitHub Docs — GITHUB_TOKEN concept page"
DOC2="https://docs.github.com/en/actions/concepts/security/github_token"
if fetch "$DOC2" doc2; then ok "GITHUB_TOKEN concept page retrieved"; else bad "could not retrieve $DOC2"; fi
assert_contains "GITHUB_TOKEN is itself an installation access token" "$WORK/doc2.txt" 'The GITHUB_TOKEN secret is a GitHub App installation access token.'
echo "--- the full 'When GITHUB_TOKEN triggers workflow runs' passage, verbatim ---"
python3 - "$WORK/doc2.txt" <<'PYEOF'
import sys, re
t = open(sys.argv[1], encoding='utf-8').read()
i = t.find('When you use the repository\'s GITHUB_TOKEN to perform tasks')
print(re.sub(r'\s+', ' ', t[i:i+1500]).strip())
PYEOF
assert_contains "the general rule the raws quote" "$WORK/doc2.txt" 'events triggered by the GITHUB_TOKEN will not create a new workflow run, with the following exceptions'
assert_contains "the pull_request carve-out both raws must be read against" "$WORK/doc2.txt" 'the resulting pull_request event creates workflow runs in an approval-required state'
assert_contains "approval is a human action by a writer" "$WORK/doc2.txt" 'a user with write access to the repository can start the runs by selecting Approve workflows to run'
assert_contains "GitHub's own remedy is an App token or a PAT" "$WORK/doc2.txt" 'use a GitHub App installation access token or a personal access token instead of GITHUB_TOKEN when creating or updating the pull request'

# ---------------------------------------------------------------------------
case_ "09 GitHub Docs — triggering a workflow (the page Codex cites)"
DOC3="https://docs.github.com/en/actions/how-tos/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow"
if fetch "$DOC3" doc3; then ok "triggering-a-workflow page retrieved"; else bad "could not retrieve $DOC3"; fi
assert_contains "same approval-required carve-out on Codex's cited page" "$WORK/doc3.txt" 'the resulting pull_request event creates workflow runs in an approval-required state'

# ---------------------------------------------------------------------------
case_ "10 GitHub Docs — repository Actions settings (PR-creation default)"
DOC4="https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository"
if fetch "$DOC4" doc4; then ok "repository Actions-settings page retrieved"; else bad "could not retrieve $DOC4"; fi
echo "--- the PR-creation default, with the scope sentence that follows it ---"
echo "    (the page carries two 'By default … personal account' sentences; this anchors"
echo "     on the pull-request one, not the workflow-permissions one that precedes it)"
python3 - "$WORK/doc4.txt" <<'PYEOF'
import sys, re
t = open(sys.argv[1], encoding='utf-8').read()
i = t.find('Preventing GitHub Actions from creating or approving pull requests')
print(re.sub(r'\s+', ' ', t[i:i+420]).strip())
PYEOF
assert_contains "the default is scoped to a new PERSONAL-ACCOUNT repository" "$WORK/doc4.txt" 'By default, when you create a new repository in your personal account, workflows are not allowed to create or approve pull requests.'
assert_contains "an organization repository inherits the organization setting instead" "$WORK/doc4.txt" 'If you create a new repository in an organization, the setting is inherited from what is configured in the organization settings.'
echo "--- what the setting is documented to control ---"
grep -oE '[^.]*setting to configure whether GITHUB_TOKEN[^.]*\.' "$WORK/doc4.txt"
assert_contains "the setting is documented as governing GITHUB_TOKEN specifically" "$WORK/doc4.txt" 'setting to configure whether GITHUB_TOKEN can create and approve pull requests'
echo "NOTE: the page states the setting in terms of GITHUB_TOKEN. Whether it also"
echo "      constrains a pull request authored with a PAT is NOT stated on this page"
echo "      and is not established by this check."

# ---------------------------------------------------------------------------
case_ "11 what this check deliberately did NOT do"
cat <<'EOF'
  not done: creating a personal access token, a GitHub App, or any credential
  not done: registering or installing a GitHub App on any account
  not done: creating a repository, pushing a branch, or opening a pull request
  not done: calling any GitHub API endpoint with any token (authenticated or not)
  not done: running smorinlabs/contributors-please-action anywhere
  not done: reading either source repository's Actions secrets or run logs
             (the Opus raw reports those from an authenticated `gh api` client;
              they are carried as that raw's evidence, not re-verified here)
  consequence: the predicted `GitHub token identity lookup failed: 403` from
  passing secrets.GITHUB_TOKEN to `pat:` remains a documented-behaviour
  prediction. This check establishes what the docs and the pinned source SAY,
  not what a run DOES.
EOF

# ---------------------------------------------------------------------------
echo
echo "summary: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -eq 0 ]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
