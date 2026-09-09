#!/usr/bin/env bash
# Comparison only (not the acceptance check): run cargo-commitlint 2.1.0 (the
# native candidate introduced by the Doxa provider reports; Gemini's pick,
# OpenAI's runner-up) on the same message files with the same 11-type /
# 50 / 72 / 72 convention, to document exactly where its behaviour differs
# from committed 1.1.11. Requires ./tools/bin/cargo-commitlint (see install.log:
# COMMITLINT_NO_INSTALL=1 cargo install cargo-commitlint --locked --version 2.1.0 --root ./tools).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; M="$HERE/../messages"; BIN="$HERE/tools/bin/cargo-commitlint"
PASS=0; FAIL=0; REC=0
result(){ local id="$1" exp="$2" obs="$3" desc="$4" out="$5" v
  if [ "$exp" = record ]; then v=RECORD; REC=$((REC+1)); elif [ "$exp" = "$obs" ]; then v=PASS; PASS=$((PASS+1)); else v=FAIL; FAIL=$((FAIL+1)); fi
  printf '%-4s expected=%-6s observed=%-4s %-6s %s\n' "$id" "$exp" "$obs" "$v" "$desc"
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/       | /'; }
run_case(){ local id="$1" exp="$2" desc="$3" msg="$4"; local out rc
  out="$(cd "$HERE" && "$BIN" --config "$HERE/commitlint.toml" check --edit "$msg" 2>&1)"; rc=$?
  result "$id" "$exp" "$rc" "$desc" "$out"; }
echo "cargo-commitlint comparison run, date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "binary: $BIN ($("$BIN" --version 2>&1)); size: $(wc -c < "$BIN") bytes; os: $(uname -srm)"
echo "length semantics source: src/validator.rs in the published 2.1.0 crate counts line.chars() whole-line for header/body/footer; no URL exemption and no soft-line rule"
run_case 01 0 "conforming message" "$M/01-valid.txt"
run_case 02 1 "type not in the enum" "$M/02-bad-type.txt"
run_case 03 1 "71-col subject (whole header counted, as commitlint and committed do)" "$M/03-long-subject.txt"
run_case 04 1 "83-col body line with spaces" "$M/04-long-body-line.txt"
run_case 05 1 "bare 116-col URL body line: REJECTED at 72 with no URL exemption (its trailer regex commit.rs:105 classes the https: line as a footer, so footer-max-line-length fires); committed and commitlint both accept (DIVERGENCE)" "$M/05-url-body-line.txt"
run_case 06 1 "subject ends with a period" "$M/06-subject-period.txt"
run_case 07 1 "107-col Claude-Session trailer containing a URL: REJECTED at footer-max-line-length 72 (committed and commitlint accept) (DIVERGENCE)" "$M/07-claude-session-trailer.txt"
run_case 08 1 "96-col footer line with spaces: rejected (agreement)" "$M/08-long-footer-line.txt"
run_case 09 record "capitalised subject: its conventional preset is subject-case always [lower-case, sentence-case], not config-conventional's never [sentence-case, ...]" "$M/09-capitalised-subject.txt"
run_case 10 record "identifier-leading subject 'docs: P01 port research tree (phases 1-5)'" "$M/10-noun-phrase-subject.txt"
run_case 11 record "'fixup! ...': skipped whole-message by defaultIgnores (config.rs:412-434 skips messages starting with fixup!, squash!, WIP, wip, Merge , Revert , or equal to Initial commit)" "$M/11-fixup.txt"
run_case 17 record "100-col space-free NON-URL line: whole-line count" "$M/17-spacefree-100.txt"
run_case 19 1 "dependabot-style message: rejected on the hook path (agreement)" "$M/19-dependabot-body.txt"
run_case 20 record "default merge message: skipped whole-message by defaultIgnores (as commitlint does; committed rejects)" "$M/20-merge-message.txt"
run_case 21 1 "66-col header whose description alone is 41 cols: whole header counted (agreement with committed case 21)" "$M/21-header-over-50-description-under-50.txt"
echo "--- missing-binary posture: the crate's own installed hook template (src/hook.rs:197-198) ends with 'Warning: cargo-commitlint not found. Skipping commit message validation.' then 'exit 0' (fail-open); a direct hook-manager command instead gets the shell's 127:"
( cd "$HERE" && env PATH=/nonexistent cargo-commitlint check --edit "$M/01-valid.txt" ) 2>&1 | sed 's/^/       | /'; echo "       | exit=${PIPESTATUS[0]}"
echo "summary: PASS=$PASS FAIL=$FAIL RECORD=$REC"; [ "$FAIL" -eq 0 ] && echo "RESULT: PASS" || { echo "RESULT: FAIL"; exit 1; }
