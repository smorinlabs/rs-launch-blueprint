#!/usr/bin/env bash
# Comparison only (not the acceptance check): run commitlint on the same
# message files with the same 11-type / 50 / 72 / 72 convention, to document
# exactly where the two engines' behaviour differs. Requires `commitlint` on
# PATH (here: the mise-installed @commitlint/cli 21.0.2 on Node 26).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; M="$HERE/../messages"
PASS=0; FAIL=0; REC=0
result(){ local id="$1" exp="$2" obs="$3" desc="$4" out="$5" v
  if [ "$exp" = record ]; then v=RECORD; REC=$((REC+1)); elif [ "$exp" = "$obs" ]; then v=PASS; PASS=$((PASS+1)); else v=FAIL; FAIL=$((FAIL+1)); fi
  printf '%-4s expected=%-6s observed=%-4s %-6s %s\n' "$id" "$exp" "$obs" "$v" "$desc"
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/       | /'; }
run_case(){ local id="$1" exp="$2" desc="$3" msg="$4"; local out rc
  out="$(cd "$HERE" && commitlint --config "$HERE/commitlint.config.mjs" --edit "$msg" 2>&1)"; rc=$?
  result "$id" "$exp" "$rc" "$desc" "$out"; }
echo "commitlint comparison run, date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "commitlint: $(command -v commitlint) ($(commitlint --version 2>&1)); node: $(node --version); os: $(uname -srm)"
echo "URL exemption source: @commitlint/ensure/lib/max-line-length.js in that install (URL_REGEX = /\\bhttps?:\\/\\/\\S+/ skips the line)"
run_case 01 0 "conforming message" "$M/01-valid.txt"
run_case 02 1 "type not in the enum" "$M/02-bad-type.txt"
run_case 03 1 "71-col subject" "$M/03-long-subject.txt"
run_case 04 1 "83-col body line with spaces" "$M/04-long-body-line.txt"
run_case 05 0 "bare 116-col URL body line: commitlint's URL exemption also accepts it (agreement with committed)" "$M/05-url-body-line.txt"
run_case 06 1 "subject ends with a period" "$M/06-subject-period.txt"
run_case 07 0 "107-col Claude-Session trailer containing a URL: accepted (agreement)" "$M/07-claude-session-trailer.txt"
run_case 08 1 "96-col footer line with spaces: rejected at footer-max-line-length 72 (agreement)" "$M/08-long-footer-line.txt"
run_case 09 record "capitalised subject: commitlint subject-case rejects it; committed has no such rule (DIVERGENCE)" "$M/09-capitalised-subject.txt"
run_case 10 record "identifier-leading subject (this repo's real 'docs: P01 port research tree'): commitlint subject-case rejects it as sentence-case; committed accepts (DIVERGENCE)" "$M/10-noun-phrase-subject.txt"
run_case 11 record "'fixup! ...': commitlint ignores fixup messages by default; committed needs --fixup (mechanism differs)" "$M/11-fixup.txt"
run_case 17 record "100-col space-free NON-URL line: commitlint counts whole lines and rejects; committed's soft-line accepts (DIVERGENCE)" "$M/17-spacefree-100.txt"
run_case 19 1 "dependabot-style message: rejected by both on the hook path (agreement)" "$M/19-dependabot-body.txt"
run_case 20 record "default merge message: commitlint ignores 'Merge branch' by default; committed rejects (DIVERGENCE)" "$M/20-merge-message.txt"
echo "summary: PASS=$PASS FAIL=$FAIL RECORD=$REC"; [ "$FAIL" -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL"; exit 1; }
