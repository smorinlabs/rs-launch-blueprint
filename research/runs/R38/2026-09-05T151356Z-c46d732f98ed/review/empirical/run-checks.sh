#!/usr/bin/env bash
# R38 empirical acceptance check: `committed` 1.1.11 enforcing the
# rs-launch-blueprint commit-message convention (committed.toml in this dir).
#
# Run from this directory:  bash run-checks.sh
# Exit status 0 only when every case with an expectation matches; RECORD cases
# document behaviour without asserting it. Provisions the pinned binary into
# ./tools (git-ignored) when absent; all git repositories are created under
# ./.work and removed on exit. COMMITTED_VERSION=<x.y.z> reruns the whole check
# against another release (the recorded upgrade acceptance gate); the binary is
# installed only when ./tools holds no binary, so remove ./tools first.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$HERE/tools"; BIN="$TOOLS/bin/committed"; WANT="${COMMITTED_VERSION:-1.1.11}"  # upgrade gate: COMMITTED_VERSION=<new> bash run-checks.sh
WORK="$HERE/.work"; M="$HERE/messages"
PASS=0; FAIL=0; REC=0
trap 'rm -rf "$WORK"' EXIT

hr(){ printf '%s\n' "------------------------------------------------------------------------"; }
result(){ # id expected observed desc output
  local id="$1" exp="$2" obs="$3" desc="$4" out="$5" verdict
  if [ "$exp" = "record" ]; then verdict=RECORD; REC=$((REC+1))
  elif [ "$exp" = "$obs" ]; then verdict=PASS; PASS=$((PASS+1))
  else verdict=FAIL; FAIL=$((FAIL+1)); fi
  printf '%-4s expected=%-6s observed=%-4s %-6s %s\n' "$id" "$exp" "$obs" "$verdict" "$desc"
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/       | /'
}
run_case(){ # id expected desc dir cmd...
  local id="$1" exp="$2" desc="$3" dir="$4"; shift 4
  local out rc
  out="$(cd "$dir" && "$@" 2>&1)"; rc=$?
  result "$id" "$exp" "$rc" "$desc" "$out"
}
new_repo(){ # path
  git init -q -b main "$1"
  git -C "$1" config user.name "Test Human"
  git -C "$1" config user.email "human@example.com"
  git -C "$1" config commit.gpgsign false
}
commit_as(){ # repo name email msgfile [extra git-commit args]
  local repo="$1" name="$2" email="$3" msg="$4"; shift 4
  git -C "$repo" -c user.name="$name" -c user.email="$email" commit -q --allow-empty --no-verify -F "$msg" "$@"
}
HUMAN_N="Test Human"; HUMAN_E="human@example.com"
BOT_N="dependabot[bot]"; BOT_E="49699333+dependabot[bot]@users.noreply.github.com"

hr; echo "R38 empirical check: committed $WANT vs rs-launch-blueprint commit-message-convention"
echo "date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "cwd: $HERE"
echo "toolchain: $(rustc --version); $(cargo --version); $(git --version)"
echo "os: $(uname -srm); $(sw_vers 2>/dev/null | tr '\n' ' ' || true)"

hr; echo "0. provision committed $WANT into ./tools (cargo install --locked)"
if [ ! -x "$BIN" ]; then
  cargo install committed --locked --version "$WANT" --root "$TOOLS" 2>&1 | tail -3
fi
GOT="$("$BIN" --version)"
echo "binary: $BIN"; echo "version: $GOT"; echo "size: $(wc -c < "$BIN") bytes"
if [ "$GOT" != "committed $WANT" ]; then echo "FATAL: version mismatch"; exit 2; fi
export PATH="$TOOLS/bin:$PATH"

rm -rf "$WORK"; mkdir -p "$WORK"
REPO="$WORK/repo";   new_repo "$REPO";   cp "$HERE/committed.toml" "$REPO/committed.toml"
REPO2="$WORK/noconf"; new_repo "$REPO2"
echo "effective configuration (committed --dump-config -), read from repo-root committed.toml with no --config flag:"
(cd "$REPO" && committed --dump-config -) | sed 's/^/       | /'

hr; echo "1. hook path: committed --commit-file <message file>  (the commit-msg contract)"
run_case 01 0 "conforming message: type in enum, 33-col subject, 66-col body, Refs footer" "$REPO" committed --commit-file "$M/01-valid.txt"
run_case 02 1 "type not in the enum (wibble)" "$REPO" committed --commit-file "$M/02-bad-type.txt"
run_case 03 1 "71-col subject with spaces (soft length 63 > 50)" "$REPO" committed --commit-file "$M/03-long-subject.txt"
run_case 04 1 "83-col body line with spaces (soft length 78 > 72)" "$REPO" committed --commit-file "$M/04-long-body-line.txt"
run_case 05 0 "body line is one bare 116-col permalink URL (un-wrappable token exempt)" "$REPO" committed --commit-file "$M/05-url-body-line.txt"
run_case 06 1 "subject ends with a period" "$REPO" committed --commit-file "$M/06-subject-period.txt"
run_case 07 0 "107-col 'Claude-Session: <url>' footer trailer (URL is the final token)" "$REPO" committed --commit-file "$M/07-claude-session-trailer.txt"
run_case 08 1 "96-col footer line with spaces (footer lines share the 72 cap)" "$REPO" committed --commit-file "$M/08-long-footer-line.txt"
run_case 09 0 "capitalised subject accepted: no subject-case rule (documented divergence from commitlint)" "$REPO" committed --commit-file "$M/09-capitalised-subject.txt"
run_case 10 0 "noun-phrase subject 'docs: P01 port research tree' (imperative_subject = false; matches repo history)" "$REPO" committed --commit-file "$M/10-noun-phrase-subject.txt"
run_case 11 1 "'fixup! ...' WITHOUT --fixup --wip (bare hook form would break git commit --fixup)" "$REPO" committed --commit-file "$M/11-fixup.txt"
run_case 12 0 "'fixup! ...' WITH --fixup --wip (crate-ci's canonical commit-msg args)" "$REPO" committed --fixup --wip --commit-file "$M/11-fixup.txt"
run_case 13 1 "'WIP: still working' with the flags: WIP rule relaxed, grammar still enforced" "$REPO" committed --fixup --wip --commit-file "$M/13-wip.txt"
run_case 14 record "subject immediately followed by body (no blank line)" "$REPO" committed --commit-file "$M/14-no-blank-line.txt"
run_case 15 1 "NO committed.toml present: lower-case conventional subject fails (config is load-bearing)" "$REPO2" committed --commit-file "$M/15-lowercase-conventional.txt"
run_case 16 127 "binary absent from PATH: loud failure, never a silent pass" "$REPO" env PATH=/nonexistent committed --commit-file "$M/01-valid.txt"
run_case 17 1 "DEFECT REPRO: hard_line_length = 200 variant, 100-col space-free line rejected at 72 (checks.rs:98-100)" "$REPO" committed --config "$HERE/committed-hardline.toml" --commit-file "$M/17-spacefree-100.txt"
run_case 18 0 "recommended config (hard_line_length 0): same 100-col space-free line accepted" "$REPO" committed --commit-file "$M/17-spacefree-100.txt"
run_case 19 1 "dependabot-style message on the hook path (71-col subject, 103-col body line): the hook always uses the main config" "$REPO" committed --commit-file "$M/19-dependabot-body.txt"
run_case 20 record "git's default merge message via --commit-file (git runs commit-msg for git merge)" "$REPO" committed --fixup --wip --commit-file "$M/20-merge-message.txt"

hr; echo "2. range path: committed <rev|range>  (the CI contract; author known)"
commit_as "$REPO" "$HUMAN_N" "$HUMAN_E" "$M/01-valid.txt"; BASE="$(git -C "$REPO" rev-parse HEAD)"
run_case R1 0 "conforming commit, committed HEAD" "$REPO" committed HEAD
commit_as "$REPO" "$HUMAN_N" "$HUMAN_E" "$M/02-bad-type.txt"
run_case R2 1 "bad-type commit authored by a human" "$REPO" committed HEAD
commit_as "$REPO" "$BOT_N" "$BOT_E" "$M/02-bad-type.txt"
run_case R3 1 "same bad-type commit authored by dependabot[bot], main config: no author exemption exists" "$REPO" committed HEAD
run_case R3b 1 "same bot commit under committed.bot.toml: the type enum is still enforced for bots (intended outcome)" "$REPO" committed --config "$HERE/committed.bot.toml" HEAD
commit_as "$REPO" "$BOT_N" "$BOT_E" "$M/19-dependabot-body.txt"
run_case R4 1 "realistic dependabot message authored by dependabot[bot], main config: subject 71 > 50 (why CI selects the bot config for bot PRs)" "$REPO" committed HEAD
run_case R4b 0 "same bot commit under committed.bot.toml: widths relaxed, grammar and type still checked" "$REPO" committed --config "$HERE/committed.bot.toml" HEAD
commit_as "$REPO" "$HUMAN_N" "$HUMAN_E" "$M/19-dependabot-body.txt"
run_case R5 1 "the same dependabot message authored by a human, main config: rejected" "$REPO" committed HEAD
run_case R5b record "same human commit under committed.bot.toml: the bot config is author-agnostic; selecting it by PR author is CI's job" "$REPO" committed --config "$HERE/committed.bot.toml" HEAD
run_case R6 1 "range base..HEAD containing bad commits, main config" "$REPO" committed "$BASE..HEAD"
git -C "$REPO" checkout -q -b topic "$BASE"
commit_as "$REPO" "$HUMAN_N" "$HUMAN_E" "$M/01-valid.txt"
commit_as "$REPO" "$HUMAN_N" "$HUMAN_E" "$M/10-noun-phrase-subject.txt"
git -C "$REPO" checkout -q main
git -C "$REPO" merge -q --no-ff --no-verify -m "Merge pull request #1 from example/topic" topic
run_case R7 0 "PR-range form HEAD~..HEAD^2 on a merge checkout (the action default): linear topic commits only" "$REPO" committed HEAD~..HEAD^2
run_case R8 1 "HEAD~..HEAD including the merge commit, merge_commit = false: explicit 'Merge commits are disallowed'" "$REPO" committed HEAD~..HEAD
run_case R9 record "same range with merge_commit = true variant: merge message still fails the Conventional grammar" "$REPO" committed --config "$HERE/committed-merge-allowed.toml" HEAD~..HEAD

hr; echo "3. hook integration: raw .git/hooks/commit-msg running the recommended command (stand-in for the R37 hook manager)"
REPO3="$WORK/hooked"; new_repo "$REPO3"; cp "$HERE/committed.toml" "$REPO3/committed.toml"
printf '%s\n' '#!/bin/sh' 'exec committed --fixup --wip --commit-file "$1"' > "$REPO3/.git/hooks/commit-msg"; chmod +x "$REPO3/.git/hooks/commit-msg"
git -C "$REPO3" add committed.toml
run_case H0 0 "git commit with a conforming message passes the hook" "$REPO3" git commit -q -F "$M/01-valid.txt"
BEFORE="$(git -C "$REPO3" rev-parse HEAD)"
run_case H1 1 "git commit with a bad type is blocked by the hook" "$REPO3" git commit -q --allow-empty -F "$M/02-bad-type.txt"
AFTER="$(git -C "$REPO3" rev-parse HEAD)"; [ "$BEFORE" = "$AFTER" ] && echo "       | HEAD unchanged after the blocked commit: $BEFORE" || echo "       | UNEXPECTED: HEAD moved"
run_case H2 0 "git commit --no-verify with the same bad type bypasses the hook (commit is created)" "$REPO3" git commit -q --allow-empty --no-verify -F "$M/02-bad-type.txt"
run_case H3 1 "...and committed HEAD (the CI re-run, F157) catches the bypassed commit" "$REPO3" committed HEAD
run_case H4 0 "git commit --fixup <the conforming H0 commit> passes the hook thanks to --fixup --wip" "$REPO3" git commit -q --allow-empty --fixup "$BEFORE"
git -C "$REPO3" log -1 --format='       | fixup commit subject: %s'
git -C "$REPO3" checkout -q -b topic; git -C "$REPO3" commit -q --allow-empty -F "$M/01-valid.txt"; git -C "$REPO3" checkout -q main
run_case H5 record "git merge --no-ff topic: git runs commit-msg for merges, so the default merge message meets the hook" "$REPO3" git merge -q --no-ff topic

hr; echo "4. F160 adapter: cargo test asserts committed.toml, committed.bot.toml and .gitmessage express one convention"
run_case T1 0 "cargo test --manifest-path repo-hygiene/Cargo.toml --locked" "$HERE" cargo test --manifest-path "$HERE/repo-hygiene/Cargo.toml" --locked -q

hr; echo "summary: PASS=$PASS FAIL=$FAIL RECORD=$REC"
if [ "$FAIL" -ne 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"
