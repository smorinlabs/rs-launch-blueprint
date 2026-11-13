#!/usr/bin/env bash
# shellcheck disable=SC2016
# SC2016 is disabled deliberately for the whole file: the assertion needles are the
# standard's own text, quoted verbatim, and several contain backticks or a literal
# $XDG_STATE_HOME. Single quotes are required precisely so nothing expands.
# R56 evidence — read the org CLI Design Standard at the blob this item is bound to,
# and the two source repositories at the programme pins, and assert the exact text the
# decision quotes. Every assertion is on CONTENT at a named line, never on exit status
# alone. These repositories are outside this one, so the check SKIPs by name when they
# are absent — which is what happens on a `git archive HEAD` rerun of this tree.
set -euo pipefail
set -o pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$here/../../../../../.." && pwd)"

fail=0
ok()   { printf 'PASS %s — %s\n' "$1" "$2"; }
bad()  { printf 'FAIL %s — %s\n' "$1" "$2"; fail=$((fail + 1)); }
# assert that line $3 of the blob captured in $blob contains the substring $4
line_has() {
  local id="$1" line="$2" needle="$3" got
  got="$(sed -n "${line}p" "$blob")"
  case "$got" in
    *"$needle"*) ok "$id" "line ${line} contains [${needle}]" ;;
    *)           bad "$id" "line ${line} does not contain [${needle}]; it reads: ${got:0:120}" ;;
  esac
}

std_repo=/Users/stevemorin/c/cli-standards
std_blob=f9de0437baece3383e73ca2c5f48b7ab399b51c7
py_repo=/Users/stevemorin/c/py-launch-blueprint
ts_repo=/Users/stevemorin/c/ts-launch-blueprint
py_pin=b08bccfb55d05f15e46a83b52c5660b1881d19f5
ts_pin=cb1cbcb2e88b898e8c081b0abbfabc1630079c00

printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ ! -d "$std_repo/.git" ]; then
  printf 'SKIP check-standard — %s is not a git repository in this extraction\n' "$std_repo"
  exit 0
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/r56std-XXXXXX")"
trap 'rm -rf "$work"' EXIT
blob="$work/cli-design-standard.md"

# `git show <sha>:<path>` cannot be used here: f9de0437… is the file's blob, not a
# commit. `cat-file -t` proves the object type before the read.
objtype="$(git -C "$std_repo" cat-file -t "$std_blob")"
if [ "$objtype" = "blob" ]; then ok 'S0 object-type' "$std_blob is a blob"; else bad 'S0 object-type' "$objtype"; fi
git -C "$std_repo" cat-file -p "$std_blob" > "$blob"
lines="$(/usr/bin/wc -l < "$blob" | tr -d ' ')"
if [ "$lines" = "773" ]; then ok 'S1 blob-length' '773 lines'; else bad 'S1 blob-length' "$lines lines, expected 773"; fi
printf 'S1-detail sha256 of the extracted blob text: %s\n' "$(shasum -a 256 "$blob" | cut -d' ' -f1)"

# R10.1 (MUST/SHOULD) — the load-bearing rule. Quoted verbatim in the decision.
line_has 'S2 R10.1-heading'   544 '**R10.1 — Authentication & identity. (MUST / SHOULD)**'
line_has 'S3 R10.1-auth-group' 545 'Authentication lives under an `auth` group'
line_has 'S4 R10.1-precedence' 545 'Credentials **MUST** resolve in the order flag-supplied token'
line_has 'S5 R10.1-env-tier'   545 'env > stored credential'
line_has 'S6 R10.1-no-flag'    545 'a token **MUST NOT** be passed as a plain flag value (R5.5)'
line_has 'S7 R10.1-stored'     545 'Stored credentials **SHOULD** use the OS keychain when available, falling back to a `0600` file under `$XDG_STATE_HOME/acme/` (R5.3)'
line_has 'S8 R10.1-exit-4'     545 'Auth failures exit `4` (R6.1)'

# §10 scope — the clause that makes §10 bind a template with a remote API surface.
line_has 'S9  section10-heading' 540 '### §10 Networked tools'
line_has 'S10 section10-scope'   542 'This section applies only to CLIs that talk to a remote API or service'

# R5.5 / R5.6 — the secret rules the BASELINE-REVIEW disposition rests on.
line_has 'S11 R5.5-heading'  326 '**R5.5 — Secrets. (MUST)**'
line_has 'S12 R5.5-argv'     327 'Secrets (tokens, passwords, keys) **MUST NOT** be accepted as plain command-line flags or positionals, because argv is visible in process listings'
line_has 'S13 R5.5-channels' 327 'Accept them via environment variable, a file path, a credential helper, or stdin'
line_has 'S14 R5.5-good'     328 'acme login --token-file ./tok'
line_has 'S15 R5.5-bad'      329 'acme login --token sk_live_abc123'
line_has 'S16 R5.6-heading'  331 '**R5.6 — Secret redaction in output. (MUST)**'
line_has 'S17 R5.6-mask'     332 'Secret values (tokens, passwords, keys) **MUST** be masked in all output'

# R5.4 — why --token-file gets no env binding: the curated env list names a token, not a token path.
line_has 'S18 R5.4-curated' 322 'Only a **curated subset** of settings **SHOULD** read from the environment'

# Conformance clause and provenance: R10.1 is `derived`, not `org-locked`, so its MUST
# binds conformance but the owner can reopen it without disturbing an org-locked row.
line_has 'S19 conformance'  50 'A CLI **conforms** when it satisfies every **MUST** rule'
line_has 'S20 waiver'       50 'A SHOULD waiver **MUST** name the rule ID, describe the deviation, explain the rationale, and record the owner/date'
line_has 'S21 row26-auth'   88 '| 26 | Authentication | `auth login/logout/status`; token precedence flag-file > env > stored; keychain-first, `0600` file fallback |'
line_has 'S22 row26-derived' 88 '| derived |'
line_has 'S23 row8-orglocked' 70 '| org-locked |'

# No separate CI standard document exists. The null result is asserted, not assumed.
# One match survives the search and it is not a standard: the P02 execution ledger's
# own record of this very finding. The assertion is therefore "no match outside that
# ledger line", which is the claim the decision actually makes.
/bin/ls "$std_repo" > "$work/std-top-level.txt"
printf 'S24-detail cli-standards worktree top level: %s\n' "$(tr '\n' ' ' < "$work/std-top-level.txt")"
/usr/bin/grep -rn -i -e 'ci standard' -e 'ci-standard' -e 'CI Design Standard' \
  "$repo_root/docs" "$repo_root/research/CLAUDE.md" "$repo_root/docs/superpowers" \
  > "$work/ci-hits.txt" 2> /dev/null || true
total_hits="$(/usr/bin/wc -l < "$work/ci-hits.txt" | tr -d ' ')"
other_hits="$(/usr/bin/grep -v 'docs/planning/p02/execution-ledger.md' "$work/ci-hits.txt" | /usr/bin/wc -l | tr -d ' ' || true)"
printf 'S24-detail total matching lines (binary /usr/bin/grep): %s; outside the execution ledger: %s\n' "$total_hits" "$other_hits"
if [ "$other_hits" = "0" ]; then
  ok 'S24 no-ci-standard' "no CI-standard document is referenced anywhere outside docs/planning/p02/execution-ledger.md, which records this same finding ($total_hits total match(es))"
else
  bad 'S24 no-ci-standard' "$other_hits matching lines outside the execution ledger; the claim that no CI standard document exists must be restated"
fi
if /usr/bin/grep -q 'cli-design-standard.md' "$work/std-top-level.txt" && ! /usr/bin/grep -qi 'ci-design\|ci-standard' "$work/std-top-level.txt"; then
  ok 'S25 std-repo-holds-one-standard' 'cli-standards holds cli-design-standard.md and no CI standard file'
else
  bad 'S25 std-repo-holds-one-standard' "$(tr '\n' ' ' < "$work/std-top-level.txt")"
fi

# --- pinned source repositories -------------------------------------------------
pin_has() {
  local id="$1" repo="$2" pin="$3" path="$4" needle="$5"
  if [ ! -d "$repo/.git" ]; then printf 'SKIP %s — %s absent\n' "$id" "$repo"; return 0; fi
  if git -C "$repo" show "${pin}:${path}" 2> /dev/null | /usr/bin/grep -q -- "$needle"; then
    ok "$id" "${path} at ${pin:0:8} contains [${needle}]"
  else
    bad "$id" "${path} at ${pin:0:8} does not contain [${needle}]"
  fi
}

# py: ADR-0002 forbids a config-file token; the flag is nonetheless a plain value.
pin_has 'S26 py-adr-title'  "$py_repo" "$py_pin" docs/adr/0002-no-secrets-in-config-file.md 'secrets'
pin_has 'S27 py-token-flag' "$py_repo" "$py_pin" src/py_launch_blueprint/cli/options.py '"--token"'
# ts: the config file IS a token source, and the flag is a plain value.
pin_has 'S28 ts-file-tier'  "$ts_repo" "$ts_pin" src/lib/config.ts 'tokenSource = '"'"'file'"'"''
pin_has 'S29 ts-mode-check' "$ts_repo" "$ts_pin" src/lib/config.ts '0o077'
pin_has 'S30 ts-token-flag' "$ts_repo" "$ts_pin" src/router.ts '--token <token>'
pin_has 'S31 ts-chmod-pair' "$ts_repo" "$ts_pin" src/lib/config.ts 'chmodSync'

printf 'CHECK_FAILURES=%s\n' "$fail"
[ "$fail" -eq 0 ]
