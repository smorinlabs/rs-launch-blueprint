#!/usr/bin/env bash
# R60 revision 2 — verify the CLI Design Standard pin, the R1.3 rule text, and
# every standard line this decision cites.
#
# Harness note: `check` is never placed on the right-hand side of a pipe, because
# a piped function body runs in a subshell and its increment of `fails` is lost —
# the first draft of this script printed "ALL CHECKS PASSED" while two checks had
# in fact failed. Output is captured with $(...) and passed as an argument, so
# the counter lives in the current shell and the exit status is the real count.
set -o pipefail

STD_REPO="$HOME/c/cli-standards"
STD_FILE="cli-design-standard.md"
PIN_COMMIT="fb30a591c267a7ec1130ba4cda679eaee494b9d7"
PIN_BLOB="f9de0437baece3383e73ca2c5f48b7ab399b51c7"
PIN_SHA256="9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f"

fails=0
checks=0

check() { # check <label> <expected-substring> <actual-output>
  local label="$1" want="$2" got="$3"
  checks=$((checks + 1))
  if [ -z "$want" ]; then
    printf 'BUG   %s — empty expectation; a check that cannot fail is not evidence\n' "$label"
    fails=$((fails + 1))
    return
  fi
  if printf '%s' "$got" | grep -qF -- "$want"; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n      wanted substring: %s\n      got: %s\n' "$label" "$want" "$got"
    fails=$((fails + 1))
  fi
}

blob() { git -C "$STD_REPO" cat-file blob "$PIN_BLOB" 2>/dev/null; }
blobline() { blob | sed -n "$1p"; }

echo "=== C0. negative control: prove this harness can actually fail ==="
echo "--- the next FAIL line is deliberate; it proves a mismatch is detected ---"
check "C0 control (expected to FAIL)" "THIS-SUBSTRING-IS-ABSENT" "the pinned standard"
if [ "$fails" -eq 1 ] && [ "$checks" -eq 1 ]; then
  echo "PASS  C0 harness detected the mismatch and incremented its counter"
else
  echo "BUG   C0 harness did NOT register the mismatch (fails=$fails checks=$checks) — results below are meaningless"
  exit 99
fi
echo "--- control accounted for; counters reset, real checks follow ---"
fails=0
checks=0

echo "=== C1. the pinned commit is the last one that touched the standard ==="
out="$(git -C "$STD_REPO" log -1 --format='%H %ad %s' --date=short -- "$STD_FILE" 2>&1)"
echo "$out"
check "C1 last commit touching $STD_FILE is $PIN_COMMIT" "$PIN_COMMIT" "$out"

echo "=== C1b. the pin holds against origin/main, not just this clone ==="
# Without this, two things the decision asserts are unchecked: that fb30a591 is
# the file's LATEST commit (not merely the latest locally), and that the
# resolution recipe works from a fresh clone (it cannot, if the commit is
# unpushed). Fetch first, then compare against the remote-tracking ref.
git -C "$STD_REPO" fetch origin --quiet 2>/dev/null
out="$(git -C "$STD_REPO" log -1 --format=%H origin/main -- "$STD_FILE" 2>&1)"
echo "origin/main's newest commit touching $STD_FILE: $out"
check "C1b1 the pinned commit is origin/main's newest for this file" "$PIN_COMMIT" "$out"
if git -C "$STD_REPO" merge-base --is-ancestor "$PIN_COMMIT" origin/main 2>/dev/null; then
  out="reachable"; else out="NOT-reachable"; fi
echo "is $PIN_COMMIT reachable from origin/main? $out"
check "C1b2 the pinned commit is published, so the recipe works from a fresh clone" "reachable" "$out"
out="$(git -C "$STD_REPO" rev-parse "origin/main:$STD_FILE" 2>&1)"
echo "origin/main's blob for the file: $out"
check "C1b3 origin/main's blob is the pinned blob" "$PIN_BLOB" "$out"

echo "=== C2. the pinned blob object id resolves from that commit ==="
out="$(git -C "$STD_REPO" rev-parse "${PIN_COMMIT}:${STD_FILE}" 2>&1)"
echo "$out"
check "C2 blob id is $PIN_BLOB" "$PIN_BLOB" "$out"

echo "=== C3. the pinned blob's sha256 — the content hash a future reader compares ==="
out="$(blob | shasum -a 256)"
echo "$out"
check "C3 blob sha256 is $PIN_SHA256" "$PIN_SHA256" "$out"

echo "=== C4. the working-tree file read on 2026-09-10 is that same content ==="
out="$(shasum -a 256 "$STD_REPO/$STD_FILE" 2>&1)"
echo "$out"
check "C4 working-tree sha256 equals the pinned blob's" "$PIN_SHA256" "$out"

echo "=== C5. the blob declares Version 1.4.14, Last updated 2026-06-28 ==="
out="$(blob | sed -n '1,12p')"
echo "$out"
check "C5a header declares Version 1.4.14" "| **Version** | 1.4.14 |" "$out"
check "C5b header declares Last updated 2026-06-28" "| **Last updated** | 2026-06-28 |" "$out"
check "C5c status is Active — canonical" "| **Status** | Active — canonical |" "$out"

echo "=== C6. R1.3 at lines 133-137 of the pinned blob, and it is a MUST ==="
out="$(blob | sed -n '133,137p')"
echo "$out"
check "C6a R1.3 heading at :133 is a MUST" "**R1.3 — Noun number. (MUST)**" "$out"
check "C6b canonical form MUST be singular" \
  "Resource nouns **MUST** be **singular** in their canonical form." "$out"
check "C6c plural MAY be an undocumented alias and MUST NOT appear in help or docs" \
  "The plural form **MAY** be accepted as an undocumented alias but **MUST NOT** appear in help or docs." "$out"
check "C6d the standard rejects 'list returns many' as a reason to pluralize" \
  "so \`list\` returning many is not a reason to pluralize" "$out"
check "C6e the standard's own non-conformant example is a documented plural" \
  "documenting \`acme widgets list\` as the primary form" "$out"

echo "=== C7. R1.3 is org-locked: Decision Log row 5 is at line 67, not 70 ==="
out="$(blobline 67)"
echo "$out"
check "C7a line 67 is row 5, Noun number, org-locked" \
  "| 5 | Noun number | Singular canonical; plural accepted as undocumented alias |" "$out"
check "C7b row 5 is marked org-locked" "org-locked" "$out"

echo "=== C8. the Decision Log rows this decision cites — row N is at line 62+N ==="
out="$(blobline 63)"; echo "$out"
check "C8a row 1 Command ordering is at :63 (the decision said :70)" \
  "| 1 | Command ordering | Noun-verb default" "$out"
out="$(blobline 65)"; echo "$out"
check "C8b row 3 -v meaning is at :65 (the decision said :70)" \
  "| 3 | \`-v\` meaning |" "$out"
out="$(blobline 69)"; echo "$out"
check "C8c row 7 Env var prefix is at :69 (the decision said :70)" \
  "| 7 | Env var prefix | \`TOOL_*\` uppercase, deterministic mapping, curated subset |" "$out"
out="$(blobline 70)"; echo "$out"
check "C8d line 70 is row 8 Exit codes — R67's row, which is why :70 was copied in error" \
  "| 8 | Exit codes |" "$out"
out="$(blobline 61)"; echo "$out"
check "C8e the Decision Log table header is at :61" "| # | Axis | Decision | Basis | Source |" "$out"

echo "=== C9. the conformance checklist names R1.3 (Appendix C) ==="
out="$(blob | grep -n 'R1\.3')"
echo "$out"
check "C9a R1.3 appears at :133 and in the checklist at :635" "635:- [ ] R1.1 Noun-verb" "$out"
check "C9b the checklist item is 'R1.3 singular nouns'" "R1.3 singular nouns" "$out"
check "C9c R2.2 cross-references R1.3 for singular naming" "177:New nouns **SHOULD**" "$out"

echo "=== C10. every other standard line this decision cites, at the pinned blob ==="
while IFS='|' read -r ln want; do
  [ -z "$ln" ] && continue
  out="$(blobline "$ln")"
  printf '%s: %s\n' "$ln" "$out"
  check "C10 line $ln" "$want" "$out"
done <<'SPECS'
50|A SHOULD waiver **MUST** name the rule ID, describe the deviation, explain the rationale, and record the owner/date
124|**R1.1 — Noun-verb ordering. (MUST, Standard profile)**
129|**R1.2 — Nesting depth. (SHOULD)**
146|**R1.6 — Aliases. (MAY / MUST NOT)**
229|**R3.10 — No prefix abbreviation. (MUST)**
270|**R4.5 — Global vs command-local flags. (SHOULD)**
275|**R4.6 — Version output format. (SHOULD)**
321|**R5.4 — Environment variables. (MUST)**
579|1. The tool has a **small, fixed** set of commands (roughly ≤ 7) that act on a **single implicit resource** or no resource at all.
586|a platform tool managing `projects`, `deploys`, `tokens`, and `users` — that **MUST** use noun-verb
SPECS

echo "=== C11. R1.6 permits the hidden plural alias R1.3 allows ==="
out="$(blob | sed -n '146,149p')"
echo "$out"
check "C11a R1.6 says aliases MAY be provided" \
  "Built-in short aliases for common verbs and nouns **MAY** be provided" "$out"
check "C11b an alias MUST NOT shadow a different real command" \
  "**MUST NOT** shadow a different real command" "$out"

echo "=== C12. the standard repo is a published remote a future reader can resolve ==="
out="$(git -C "$STD_REPO" remote get-url origin 2>&1)"
echo "$out"
check "C12 origin is smorinlabs/cli-standards" "github.com/smorinlabs/cli-standards" "$out"

echo "=== C13. both source ports DOCUMENT the plural noun — what R1.3 changes ==="
out="$(git -C "$HOME/c/py-launch-blueprint" show \
  'b08bccfb:src/py_launch_blueprint/cli/commands/projects.py' 2>/dev/null | sed -n '37p')"
echo "py projects.py:37: $out"
check "C13a py declares a help-visible click group named projects" \
  '@click.group(name="projects"' "$out"
out="$(git -C "$HOME/c/py-launch-blueprint" show \
  'b08bccfb:src/py_launch_blueprint/cli/commands/__init__.py' 2>/dev/null | grep -n 'COMMAND_GROUPS = ')"
echo "py commands/__init__.py: $out"
check "C13b py registers projects_group and config_group" \
  "COMMAND_GROUPS = [projects_group, config_group]" "$out"
out="$(git -C "$HOME/c/ts-launch-blueprint" show 'cb1cbcb2:src/router.ts' 2>/dev/null | grep -n "'projects'")"
echo "ts router.ts: $out"
check "C13c ts registers a command literally named projects" "'projects'" "$out"

echo "=== C14. the R60 revision-1 blob, for the preservation diff ==="
R1_BLOB="5ae06c378ee71a8d6b16eb394862806284c72ca5"
R1_SHA256="d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c"
out="$(git -C "$HOME/c/rs-launch-blueprint-p02-plan" rev-parse \
  'HEAD:research/runs/R60/2026-09-05T183002Z-09f93cfc507c/review/DECISION.md' 2>&1)"
echo "$out"
check "C14a revision-1 blob id is $R1_BLOB" "$R1_BLOB" "$out"
out="$(git -C "$HOME/c/rs-launch-blueprint-p02-plan" cat-file blob "$R1_BLOB" 2>/dev/null | shasum -a 256)"
echo "$out"
check "C14b revision-1 blob sha256 is the one the audit rejected" "$R1_SHA256" "$out"

echo "=== C15. R67 records NO version pin for the same standard ==="
# A negative claim, so it is asserted as an explicit count of zero rather than as
# the absence of output: any nonzero count here would falsify "R67 did not pin".
R67D="$HOME/c/rs-launch-blueprint-p02-plan/research/topics/67-error-and-exit-code-contract/DECISION.md"
R67E="$HOME/c/rs-launch-blueprint-p02-plan/research/topics/67-error-and-exit-code-contract/evidence"
out="$(grep -c '1\.4\.14' "$R67D" 2>/dev/null)"
echo "R67 DECISION.md occurrences of '1.4.14': $out"
check "C15a R67 body names no standard version 1.4.14" "0" "$out"
out="$(grep -cE 'cli-design-standard\.md[^:]*(v?1\.4|commit|blob|sha256)' "$R67D" 2>/dev/null)"
echo "R67 standard citations carrying a version/commit/hash: $out"
check "C15b R67's standard citations carry no version, commit or hash" "0" "$out"
out="$(grep -c 'cli-design-standard' "$R67D" 2>/dev/null)"
echo "R67 lines citing cli-design-standard.md: $out"
check "C15c R67 does cite the standard (2 lines: :78 and :464) — the absence above is a real gap, not a missing file" "2" "$out"
# R67's AUDIT trail, unlike its body, does name the version. Recorded because it
# independently attests that R67 and R60 read the same revision.
out="$(grep -rl '1\.4\.14' "$R67E" 2>/dev/null | wc -l | tr -d ' ')"
echo "R67 evidence files mentioning '1.4.14': $out"
check "C15d exactly 2 R67 evidence files mention 1.4.14" "2" "$out"
out="$(sed -n '6p' "$R67E/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract-r4.log" 2>/dev/null)"
echo "R67 r4 audit log:6: $out"
check "C15e R67's revision-4 auditor recorded the standard as version 1.4.14" \
  "Standard read: \`/Users/stevemorin/c/cli-standards/cli-design-standard.md\`, version 1.4.14." "$out"
out="$(grep -c '1\.4\.14' "$R67E/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract.log" 2>/dev/null)"
echo "the other file's mentions (the standard's own changelog row 54, quoted): $out"
check "C15f the second mention is a single quoted changelog line, not a pin" "1" "$out"

echo "=== C16. ts declares the plural noun in commands/projects.ts, not router.ts ==="
out="$(git -C "$HOME/c/ts-launch-blueprint" show 'cb1cbcb2:src/commands/projects.ts' 2>/dev/null | sed -n '70p')"
echo "ts commands/projects.ts:70: $out"
check "C16 ts declares .command('projects', { isDefault: true }) at :70" \
  ".command('projects', { isDefault: true })" "$out"

echo "=== C17. the clap 4.6.6 APIs the new acceptance criteria name actually exist ==="
CB_DIR="/private/tmp/r60-r2-verify/clap_builder-4.6.6"
CB_SHA="7b48fea5a88e9ae728a2dcbedbfc0e730f7d60da42e1cb049a83c9fb8b789889"
if [ ! -d "$CB_DIR" ]; then
  echo "SKIP  C17 — $CB_DIR absent; re-fetch with:"
  echo "      curl -sSL -o clap_builder-4.6.6.crate https://static.crates.io/crates/clap_builder/clap_builder-4.6.6.crate && tar xzf clap_builder-4.6.6.crate"
  fails=$((fails + 1)); checks=$((checks + 1))
else
  out="$(shasum -a 256 /private/tmp/r60-r2-verify/clap_builder-4.6.6.crate 2>/dev/null)"
  echo "$out"
  check "C17a the unpacked tarball's sha256 matches crates.io's recorded checksum" "$CB_SHA" "$out"
  while IFS='|' read -r fn ln; do
    [ -z "$fn" ] && continue
    out="$(sed -n "${ln}p" "$CB_DIR/src/builder/command.rs")"
    printf 'command.rs:%s: %s\n' "$ln" "$out"
    check "C17 Command::$fn at command.rs:$ln" "pub fn $fn" "$out"
  done <<'APIS'
get_subcommands|3932
get_name|3756
is_hide_set|4242
render_long_help|1037
get_visible_aliases|3847
get_all_aliases|3874
alias|2691
visible_alias|2893
APIS
  out="$(sed -n '2664,2666p' "$CB_DIR/src/builder/command.rs")"
  echo "$out"
  check "C17b Command::alias is documented as HIDDEN from help" \
    "Aliases defined with this method are *hidden* from the help" "$out"
  out="$(sed -n '2865,2868p' "$CB_DIR/src/builder/command.rs")"
  echo "$out"
  check "C17c Command::visible_alias is documented as VISIBLE in help" \
    "The alias defined with this method is *visible* from the help" "$out"
fi

echo "=== C18. clap_derive 4.6.4 forwards #[command(alias = ...)] to Command::alias ==="
# The R1.3 fix rests on #[command(alias = "projects")] reaching the HIDDEN-alias
# builder method. C17 proved the builder method's behavior; this proves the
# derive actually calls it rather than intercepting the name.
CD_DIR="/private/tmp/r60-r2-verify/clap_derive-4.6.4"
CD_SHA="d012d2b9d65aca7f18f4d9878a045bc17899bba951561ba5ec3c2ba1eed9a061"
if [ ! -d "$CD_DIR" ]; then
  echo "SKIP  C18 — $CD_DIR absent; re-fetch with:"
  echo "      curl -sSL -o clap_derive-4.6.4.crate https://static.crates.io/crates/clap_derive/clap_derive-4.6.4.crate && tar xzf clap_derive-4.6.4.crate"
  fails=$((fails + 1)); checks=$((checks + 1))
else
  out="$(shasum -a 256 /private/tmp/r60-r2-verify/clap_derive-4.6.4.crate 2>/dev/null)"
  echo "$out"
  check "C18a the tarball's sha256 matches crates.io's recorded checksum" "$CD_SHA" "$out"
  out="$(sed -n '337,345p' "$CD_DIR/src/item.rs")"
  echo "$out"
  check "C18b a non-special attribute name is pushed as a Method verbatim" \
    "_ => self.methods.push(Method::new(name, arg))," "$out"
  out="$(sed -n '1281,1289p' "$CD_DIR/src/item.rs")"
  echo "$out"
  check "C18c a Method renders as a builder call .<name>(<args>)" \
    'quote!( .#name(#args) )' "$out"
  # 'alias' must not be intercepted as a MagicAttrName, or the path above is moot.
  out="$(grep -c 'alias' "$CD_DIR/src/attr.rs")"
  echo "occurrences of 'alias' in clap_derive's attribute table (attr.rs): $out"
  check "C18d 'alias' is not a magic attribute name, so it forwards verbatim" "0" "$out"
  out="$(grep -cE '^\s+Alias,' "$CD_DIR/src/attr.rs")"
  echo "MagicAttrName::Alias variants: $out"
  check "C18e there is no MagicAttrName::Alias variant" "0" "$out"
fi

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
