#!/usr/bin/env bash
# R60 revision 3 — verify the CLI Design Standard pin, the R1.3 rule text, every
# standard line this decision cites, and the clap APIs AC9/AC10 name.
#
# WHY THIS SCRIPT EXISTS IN THIS FORM. Revision 2's equivalent script was rejected
# because it could not be rerun once the revision was committed. It read the
# authoring machine's home directory (`$HOME/c/cli-standards`, `$HOME/c/py-launch-blueprint`),
# a scratch directory outside the repository (`/private/tmp/r60-r2-verify/…`) that
# no longer existed, and the working tree's dirty state. This rewrite reads only:
#
#   * files committed under `review/evidence/snapshots/` in this same run directory,
#     each verified against the sha256 recorded in `snapshots/MANIFEST.txt` before
#     it is read; and
#   * files committed elsewhere in this repository, reached by a path derived from
#     this script's own location.
#
# It makes no network call, needs no git repository, and reads nothing outside the
# checkout. Where a snapshot came from is recorded in `snapshots/MANIFEST.txt` and
# re-derived over the network by `r60-snapshot-provenance-r3.sh`.
#
# Output is location-independent on purpose: no absolute path is ever printed, and
# `shasum` is fed on stdin so it prints `-` rather than a file name. That is what
# lets the saved log be diffed byte-for-byte against a rerun in any directory.
#
# Harness note, carried from revision 2: `check` is never placed on the right-hand
# side of a pipe, because a piped function body runs in a subshell and its increment
# of `fails` is lost — an early draft printed "ALL CHECKS PASSED" while two checks
# had in fact failed. Output is captured with $(...) and passed as an argument.
set -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"
RUN_DIR="$(cd "$HERE/../.." && pwd)"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"

STD="$SNAP/cli-design-standard-1.4.14.md"
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

sha() { shasum -a 256 < "$1" | awk '{print $1}'; }   # stdin, so no path is printed
stdline() { sed -n "$1p" "$STD"; }

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

echo "=== C1. every snapshot this script reads is the one MANIFEST.txt records ==="
# The integrity anchor for everything below. A snapshot edited after the fact
# fails here before any content assertion is allowed to read it.
listed=0
while IFS= read -r row; do
  case "$row" in ''|'#'*) continue ;; esac
  IFS='|' read -r want_sha file kind origin inner tarsha <<<"$row"
  listed=$((listed + 1))
  if [ ! -f "$SNAP/$file" ]; then
    got="MISSING"
  else
    got="$(sha "$SNAP/$file")"
  fi
  printf '%s  %s\n' "$got" "$file"
  check "C1 $file matches its recorded sha256" "$want_sha" "$got"
done < "$SNAP/MANIFEST.txt"
echo "snapshot files listed in MANIFEST.txt: $listed"
check "C1x MANIFEST.txt lists 10 snapshots" "listed=10" "listed=$listed"
present="$(find "$SNAP" -type f ! -name 'MANIFEST.txt' | wc -l | tr -d ' ')"
echo "snapshot files present on disk (excluding MANIFEST.txt): $present"
check "C1y no snapshot file is present that MANIFEST.txt does not record" "listed=$listed present=$listed" "listed=$listed present=$present"

echo "=== C2. the standard snapshot IS the pinned revision, by content hash ==="
# This is the whole pin in one line: the committed snapshot hashes to the sha256
# that git blob f9de0437 (commit fb30a591) hashes to. Every ':<line>' citation
# below is therefore a citation into that blob, not into whatever the standards
# repository holds today. That the pin is still the file's newest published commit
# is a live-history claim and is checked by r60-snapshot-provenance-r3.sh, not here.
out="$(sha "$STD")"
echo "$out"
check "C2a the snapshot's sha256 is the pinned blob's, $PIN_SHA256" "$PIN_SHA256" "$out"
out="$(grep -F "$PIN_COMMIT" "$SNAP/MANIFEST.txt")"
echo "MANIFEST origin row for the standard: $out"
check "C2b the snapshot's recorded origin is commit $PIN_COMMIT" "$PIN_COMMIT" "$out"
check "C2c that origin is the published cli-standards repository" \
  "raw.githubusercontent.com/smorinlabs/cli-standards/" "$out"
out="$(wc -l < "$STD" | tr -d ' ')"
echo "lines in the pinned standard: $out"
check "C2d the pinned standard is 773 lines, so every line citation below is in range" "lines=773" "lines=$out"

echo "=== C3. the pinned text declares Version 1.4.14, Last updated 2026-06-28 ==="
out="$(sed -n '1,12p' "$STD")"
echo "$out"
check "C3a header declares Version 1.4.14" "| **Version** | 1.4.14 |" "$out"
check "C3b header declares Last updated 2026-06-28" "| **Last updated** | 2026-06-28 |" "$out"
check "C3c status is Active — canonical" "| **Status** | Active — canonical |" "$out"

echo "=== C4. R1.3 at lines 133-137 of the pinned text, and it is a MUST ==="
out="$(sed -n '133,137p' "$STD")"
echo "$out"
check "C4a R1.3 heading at :133 is a MUST" "**R1.3 — Noun number. (MUST)**" "$out"
check "C4b canonical form MUST be singular" \
  "Resource nouns **MUST** be **singular** in their canonical form." "$out"
check "C4c plural MAY be an undocumented alias and MUST NOT appear in help or docs" \
  "The plural form **MAY** be accepted as an undocumented alias but **MUST NOT** appear in help or docs." "$out"
check "C4d the standard rejects 'list returns many' as a reason to pluralize" \
  "so \`list\` returning many is not a reason to pluralize" "$out"
check "C4e the standard's own non-conformant example is a documented plural" \
  "documenting \`acme widgets list\` as the primary form" "$out"

echo "=== C5. R1.3 is org-locked: Decision Log row 5 is at line 67, not 70 ==="
out="$(stdline 67)"
echo "$out"
check "C5a line 67 is row 5, Noun number, org-locked" \
  "| 5 | Noun number | Singular canonical; plural accepted as undocumented alias |" "$out"
check "C5b row 5 is marked org-locked" "org-locked" "$out"

echo "=== C6. the Decision Log rows this decision cites — row N is at line 62+N ==="
out="$(stdline 63)"; echo "$out"
check "C6a row 1 Command ordering is at :63 (revision 1 said :70)" \
  "| 1 | Command ordering | Noun-verb default" "$out"
out="$(stdline 65)"; echo "$out"
check "C6b row 3 -v meaning is at :65 (revision 1 said :70)" \
  "| 3 | \`-v\` meaning |" "$out"
out="$(stdline 69)"; echo "$out"
check "C6c row 7 Env var prefix is at :69 (revision 1 said :70)" \
  "| 7 | Env var prefix | \`TOOL_*\` uppercase, deterministic mapping, curated subset |" "$out"
out="$(stdline 70)"; echo "$out"
check "C6d line 70 is row 8 Exit codes — R67's row, which is why :70 was copied in error" \
  "| 8 | Exit codes |" "$out"
out="$(stdline 61)"; echo "$out"
check "C6e the Decision Log table header is at :61" "| # | Axis | Decision | Basis | Source |" "$out"

echo "=== C7. the conformance checklist names R1.3 (Appendix C) ==="
out="$(grep -n 'R1\.3' "$STD")"
echo "$out"
check "C7a R1.3 appears at :133 and in the checklist at :635" "635:- [ ] R1.1 Noun-verb" "$out"
check "C7b the checklist item is 'R1.3 singular nouns'" "R1.3 singular nouns" "$out"
check "C7c R2.2 cross-references R1.3 for singular naming" "177:New nouns **SHOULD**" "$out"

echo "=== C8. every other standard line this decision cites, at the pinned text ==="
while IFS='|' read -r ln want; do
  [ -z "$ln" ] && continue
  out="$(stdline "$ln")"
  printf '%s: %s\n' "$ln" "$out"
  check "C8 line $ln" "$want" "$out"
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

echo "=== C9. R1.6 permits the hidden plural alias R1.3 allows ==="
out="$(sed -n '146,149p' "$STD")"
echo "$out"
check "C9a R1.6 says aliases MAY be provided" \
  "Built-in short aliases for common verbs and nouns **MAY** be provided" "$out"
check "C9b an alias MUST NOT shadow a different real command" \
  "**MUST NOT** shadow a different real command" "$out"

echo "=== C10. both source ports DOCUMENT the plural noun — what R1.3 changes ==="
out="$(sed -n '37p' "$SNAP/py-b08bccfb-cli-commands-projects.py.txt")"
echo "py projects.py:37: $out"
check "C10a py declares a help-visible click group named projects" \
  '@click.group(name="projects"' "$out"
out="$(grep -n 'COMMAND_GROUPS = ' "$SNAP/py-b08bccfb-cli-commands-__init__.py.txt")"
echo "py commands/__init__.py: $out"
check "C10b py registers projects_group and config_group" \
  "COMMAND_GROUPS = [projects_group, config_group]" "$out"
out="$(grep -n "'projects'" "$SNAP/ts-cb1cbcb2-src-router.ts.txt")"
echo "ts router.ts: $out"
check "C10c ts looks the command up by the literal name projects" "'projects'" "$out"
out="$(sed -n '70p' "$SNAP/ts-cb1cbcb2-src-commands-projects.ts.txt")"
echo "ts commands/projects.ts:70: $out"
check "C10d ts declares .command('projects', { isDefault: true }) at :70" \
  ".command('projects', { isDefault: true })" "$out"

echo "=== C11. the clap 4.6.6 APIs the new acceptance criteria name actually exist ==="
CB="$SNAP/clap_builder-4.6.6-src-builder-command.rs.txt"
out="$(grep -F 'clap_builder-4.6.6.crate' "$SNAP/MANIFEST.txt" | head -1)"
echo "MANIFEST origin row for command.rs: $out"
check "C11z the snapshot's origin is the published 4.6.6 tarball and its crates.io checksum" \
  "7b48fea5a88e9ae728a2dcbedbfc0e730f7d60da42e1cb049a83c9fb8b789889" "$out"
while IFS='|' read -r fn ln; do
  [ -z "$fn" ] && continue
  out="$(sed -n "${ln}p" "$CB")"
  printf 'command.rs:%s: %s\n' "$ln" "$out"
  check "C11 Command::$fn at command.rs:$ln" "pub fn $fn" "$out"
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
out="$(sed -n '2664,2666p' "$CB")"
echo "$out"
check "C11b Command::alias is documented as HIDDEN from help" \
  "Aliases defined with this method are *hidden* from the help" "$out"
out="$(sed -n '2865,2868p' "$CB")"
echo "$out"
check "C11c Command::visible_alias is documented as VISIBLE in help" \
  "The alias defined with this method is *visible* from the help" "$out"

echo "=== C12. clap_derive 4.6.4 forwards #[command(alias = ...)] to Command::alias ==="
# The R1.3 fix rests on #[command(alias = "projects")] reaching the HIDDEN-alias
# builder method. C11 proved the builder method's behavior; this proves the derive
# actually calls it rather than intercepting the name.
CD_ITEM="$SNAP/clap_derive-4.6.4-src-item.rs.txt"
CD_ATTR="$SNAP/clap_derive-4.6.4-src-attr.rs.txt"
out="$(grep -F 'clap_derive-4.6.4.crate' "$SNAP/MANIFEST.txt" | head -1)"
echo "MANIFEST origin row for item.rs: $out"
check "C12z the snapshot's origin is the published 4.6.4 tarball and its crates.io checksum" \
  "d012d2b9d65aca7f18f4d9878a045bc17899bba951561ba5ec3c2ba1eed9a061" "$out"
out="$(sed -n '337,345p' "$CD_ITEM")"
echo "$out"
check "C12b a non-special attribute name is pushed as a Method verbatim" \
  "_ => self.methods.push(Method::new(name, arg))," "$out"
out="$(sed -n '1281,1289p' "$CD_ITEM")"
echo "$out"
check "C12c a Method renders as a builder call .<name>(<args>)" \
  'quote!( .#name(#args) )' "$out"
# 'alias' must not be intercepted as a MagicAttrName, or the path above is moot.
out="$(grep -c 'alias' "$CD_ATTR")"
echo "occurrences of 'alias' in clap_derive's attribute table (attr.rs): $out"
check "C12d 'alias' is not a magic attribute name, so it forwards verbatim" "count=0" "count=$out"
out="$(grep -cE '^\s+Alias,' "$CD_ATTR")"
echo "MagicAttrName::Alias variants: $out"
check "C12e there is no MagicAttrName::Alias variant" "count=0" "count=$out"

echo "=== C13. R67 records NO version pin for the same standard ==="
# A negative claim, so it is asserted as an explicit count of zero rather than as
# the absence of output: any nonzero count here would falsify "R67 did not pin".
# These paths are this repository's own published R67 topic, reached relative to
# this script, so the check runs from any checkout of this commit.
R67D="$REPO_ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
R67E="$REPO_ROOT/research/topics/67-error-and-exit-code-contract/evidence"
out="$([ -f "$R67D" ] && echo present || echo MISSING)"
echo "R67 published decision: $out"
check "C13z R67's published decision is in this checkout, so the counts below are real" "present" "$out"
out="$(grep -c '1\.4\.14' "$R67D")"
echo "R67 DECISION.md occurrences of '1.4.14': $out"
check "C13a R67 body names no standard version 1.4.14" "count=0" "count=$out"
out="$(grep -cE 'cli-design-standard\.md[^:]*(v?1\.4|commit|blob|sha256)' "$R67D")"
echo "R67 standard citations carrying a version/commit/hash: $out"
check "C13b R67's standard citations carry no version, commit or hash" "count=0" "count=$out"
out="$(grep -c 'cli-design-standard' "$R67D")"
echo "R67 lines citing cli-design-standard.md: $out"
check "C13c R67 does cite the standard (2 lines: :78 and :464) — the absence above is a real gap, not a missing file" "count=2" "count=$out"
# R67's AUDIT trail, unlike its body, does name the version. Recorded because it
# independently attests that R67 and R60 read the same revision.
out="$(grep -rl '1\.4\.14' "$R67E" | wc -l | tr -d ' ')"
echo "R67 evidence files mentioning '1.4.14': $out"
check "C13d exactly 2 R67 evidence files mention 1.4.14" "count=2" "count=$out"
out="$(sed -n '6p' "$R67E/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract-r4.log")"
echo "R67 r4 audit log:6: $out"
check "C13e R67's revision-4 auditor recorded the standard as version 1.4.14" \
  "cli-design-standard.md\`, version 1.4.14." "$out"
out="$(grep -c '1\.4\.14' "$R67E/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract.log")"
echo "the other file's mentions (the standard's own changelog row 54, quoted): $out"
check "C13f the second mention is a single quoted changelog line, not a pin" "count=1" "count=$out"

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
