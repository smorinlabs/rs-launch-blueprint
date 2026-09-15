#!/usr/bin/env bash
# R60 revision 5 — verify the CLI Design Standard pin, the R1.3 rule text, every
# standard line this decision cites, the clap APIs AC9/AC10 name, the R4.6 rule
# text that F267's decided option (b) rests on, the four clap version-flag APIs
# that deliver it, the R66 coupling's factual basis, and — new in revision 5 —
# THE OWNER'S RULING ITSELF, now that it is written into this repository.
#
# WHAT REVISION 5 CHANGED, AND WHY. This script is `r60-standard-pin-r4.sh` with
# one region rewritten. The revision-4 audit (verdict REJECT, finding F1) reran
# that script and it FAILED: its C16h and C16i asserted that the owner's ruling
# of 2026-09-14 was ABSENT from `docs/port/OWNER-REVIEW.md` (`OV-01` count 0,
# `2026-09-14` count 0), which was true when revision 4 was written and false by
# the time it was audited — the programme controller had written the ruling into
# that file at :72-91. The rerun observed counts 3 and 1.
#
#   C16h..C16n now assert the record's PRESENCE, clause by clause, and they do it
#   by ANCHORING rather than by counting the whole file. A file-wide count of
#   `OV-01` would be the same mistake in mirror image: that file is owned by the
#   controller and gains sections over time, so the next section it gains would
#   break the count. Instead the ruling's section is located by its heading,
#   extracted, and each clause this decision relies on is asserted INSIDE the
#   extraction. C16m is the control that keeps the extraction honest: a string
#   that exists elsewhere in the same file must NOT appear inside the extracted
#   section, so an extraction that silently widened to the whole file fails.
#   The raw file-wide counts are still PRINTED, beside the grep binary and its
#   version, as information rather than as checks.
#
#   `r60-standard-pin-r4.sh` is left BYTE-IDENTICAL beside this file. It is the
#   artifact the revision-4 audit ran, and its failure is part of the record.
#
#   GREP is pinned to /usr/bin/grep by absolute path and its version is printed,
#   so a count in this log names the binary that produced it. A typed `grep` in
#   an agent shell on this machine can resolve to `ugrep`, which honors
#   .gitignore and would silently change what a search sees.
#
# WHAT REVISION 4 ADDED, AND WHY EACH ADDITION IS LOAD-BEARING.
#   C8   gains the two R4.6 body lines (:276 the rule, :277 the worked example).
#        Revisions 1-3 cited R4.6 as ':275-279', which overruns the rule by two
#        lines into a blank line and R4.7's heading; the corrected range is
#        ':275-277' and every claim revision 4 relies on cites ':276' or ':277'.
#   C14  is new: ArgAction::Version returns Err(version_err) immediately, so the
#        parse stops at --version and no format flag after it is ever read. That
#        is the single fact that makes option (b) cost more than an acceptance-
#        criteria rewrite, so it is read from a hash-verified committed snapshot
#        of parser.rs rather than from a remembered line number.
#   C15  is new: the four Command APIs the decided mechanism names —
#        render_version, disable_version_flag, version, long_version — exist at
#        the cited lines, and disable_version_flag's own doctest asserts the
#        UnknownArgument behavior the decision describes.
#   C16  is new: R66 owns no registry parameter. That is the checked reason the
#        decision records a 'related (not a registry dependency)' note instead of
#        a 'CONFLICT: R66 <param>' line, which would have to name a parameter
#        that does not exist.
#   C17  is new: the decision declares no override and claims no waiver. This is
#        the inverse of revision 3's C4f family, which required the waiver to be
#        outstanding; that requirement is ended by the owner's 2026-09-14 ruling.
#        It lives in the preservation script, not here.
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
# re-derived over the network by `r60-snapshot-provenance-r4.sh`.
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

GREP=/usr/bin/grep   # absolute, never PATH: a typed `grep` here can be ugrep

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"
RUN_DIR="$(cd "$HERE/../.." && pwd)"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"

STD="$SNAP/cli-design-standard-1.4.14.md"
REGISTRY="$REPO_ROOT/docs/port/PARAMETERS.md"
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
  if printf '%s' "$got" | "$GREP" -qF -- "$want"; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n      wanted substring: %s\n      got: %s\n' "$label" "$want" "$got"
    fails=$((fails + 1))
  fi
}

sha() { shasum -a 256 < "$1" | awk '{print $1}'; }   # stdin, so no path is printed
stdline() { sed -n "$1p" "$STD"; }

echo "=== C-grep. the search binary every count below was produced by ==="
# Recorded beside the counts because a count is only as good as the tool that
# produced it. /usr/bin/grep is used by absolute path throughout this script.
GREP_VERSION="$("$GREP" --version 2>&1 | head -1)"
echo "grep binary:  $GREP"
echo "grep version: $GREP_VERSION"

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

check "C-grep the search binary is an absolute /usr/bin/grep that reports a version" \
  "grep" "$GREP:$GREP_VERSION"

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
check "C1x MANIFEST.txt lists 12 snapshots" "listed=12" "listed=$listed"
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
out="$("$GREP" -F "$PIN_COMMIT" "$SNAP/MANIFEST.txt")"
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
out="$("$GREP" -n 'R1\.3' "$STD")"
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
276|`--version`/`-V` **SHOULD** print a single line `acme <semver>` (GNU name-and-version style)
277|✅ `acme 1.4.0`; `acme --version -o json`
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
out="$("$GREP" -n 'COMMAND_GROUPS = ' "$SNAP/py-b08bccfb-cli-commands-__init__.py.txt")"
echo "py commands/__init__.py: $out"
check "C10b py registers projects_group and config_group" \
  "COMMAND_GROUPS = [projects_group, config_group]" "$out"
out="$("$GREP" -n "'projects'" "$SNAP/ts-cb1cbcb2-src-router.ts.txt")"
echo "ts router.ts: $out"
check "C10c ts looks the command up by the literal name projects" "'projects'" "$out"
out="$(sed -n '70p' "$SNAP/ts-cb1cbcb2-src-commands-projects.ts.txt")"
echo "ts commands/projects.ts:70: $out"
check "C10d ts declares .command('projects', { isDefault: true }) at :70" \
  ".command('projects', { isDefault: true })" "$out"

echo "=== C11. the clap 4.6.6 APIs the new acceptance criteria name actually exist ==="
CB="$SNAP/clap_builder-4.6.6-src-builder-command.rs.txt"
out="$("$GREP" -F 'clap_builder-4.6.6.crate' "$SNAP/MANIFEST.txt" | head -1)"
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
out="$("$GREP" -F 'clap_derive-4.6.4.crate' "$SNAP/MANIFEST.txt" | head -1)"
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
out="$("$GREP" -c 'alias' "$CD_ATTR")"
echo "occurrences of 'alias' in clap_derive's attribute table (attr.rs): $out"
check "C12d 'alias' is not a magic attribute name, so it forwards verbatim" "count=0" "count=$out"
out="$("$GREP" -cE '^\s+Alias,' "$CD_ATTR")"
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
out="$("$GREP" -c '1\.4\.14' "$R67D")"
echo "R67 DECISION.md occurrences of '1.4.14': $out"
check "C13a R67 body names no standard version 1.4.14" "count=0" "count=$out"
out="$("$GREP" -cE 'cli-design-standard\.md[^:]*(v?1\.4|commit|blob|sha256)' "$R67D")"
echo "R67 standard citations carrying a version/commit/hash: $out"
check "C13b R67's standard citations carry no version, commit or hash" "count=0" "count=$out"
out="$("$GREP" -c 'cli-design-standard' "$R67D")"
echo "R67 lines citing cli-design-standard.md: $out"
check "C13c R67 does cite the standard (2 lines: :78 and :464) — the absence above is a real gap, not a missing file" "count=2" "count=$out"
# R67's AUDIT trail, unlike its body, does name the version. Recorded because it
# independently attests that R67 and R60 read the same revision.
out="$("$GREP" -rl '1\.4\.14' "$R67E" | wc -l | tr -d ' ')"
echo "R67 evidence files mentioning '1.4.14': $out"
check "C13d exactly 2 R67 evidence files mention 1.4.14" "count=2" "count=$out"
out="$(sed -n '6p' "$R67E/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract-r4.log")"
echo "R67 r4 audit log:6: $out"
check "C13e R67's revision-4 auditor recorded the standard as version 1.4.14" \
  "cli-design-standard.md\`, version 1.4.14." "$out"
out="$("$GREP" -c '1\.4\.14' "$R67E/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract.log")"
echo "the other file's mentions (the standard's own changelog row 54, quoted): $out"
check "C13f the second mention is a single quoted changelog line, not a pin" "count=1" "count=$out"

echo "=== C8b. R4.6 spans :275-277 — the range revisions 1-3 cited overran it ==="
# The decision keeps the historical ':275-279' and ':277-279' byte-identical as
# the record, and cites ':276'/':277' for everything revision 4 relies on. This
# check is what makes that correction a fact rather than an assertion: the rule
# body is one line at :276, the worked example is :277, :278 is blank and :279
# is the heading of the NEXT rule.
out="$(stdline 276)"
printf '276: %s\n' "$out"
check "C8b1 :276 carries R4.6's single-line SHOULD" \
  '**SHOULD** print a single line `acme <semver>`' "$out"
check "C8b2 :276 permits --version to honor -o json / --output json" \
  '`--version` **MAY** honor `-o json`/`--output json`' "$out"
check "C8b3 :276 gives the JSON object shape as an example, not a closed set" \
  'it **SHOULD** emit an object such as' "$out"
check "C8b4 :276 makes version a SemVer MUST with no leading v" \
  '`version` **MUST** be SemVer without a leading `v`' "$out"
check "C8b5 :276 lets commit and built be omitted or null when unknown" \
  'while `commit` and `built` **MAY** be omitted or `null` when unknown' "$out"
out="$(stdline 277)"
printf '277: %s\n' "$out"
check "C8b6 :277 is the worked example the decision cites" \
  '`acme --version -o json`' "$out"
out="$(stdline 278)"
printf '278: [%s]\n' "$out"
check "C8b7 :278 is blank, so R4.6's body ends at :277" "blank=yes" \
  "blank=$([ -z "$out" ] && echo yes || echo no)"
out="$(stdline 279)"
printf '279: %s\n' "$out"
check "C8b8 :279 is R4.7's heading — the two lines the old range overran" \
  '**R4.7 — Concurrency. (MAY)**' "$out"

echo "=== C14. ArgAction::Version TERMINATES the parse — why option (b) costs more ==="
# The single new mechanical fact in revision 4. If this arm returned Ok, a format
# flag after --version would be parsed and clap's built-in version flag could
# carry option (b) unchanged; because it returns Err, it cannot, and F267's
# mechanism has to disable the built-in flag. Read from a hash-verified snapshot
# of the exact published file (C1 above), not from a remembered line number.
PR="$SNAP/clap_builder-4.6.6-src-parser-parser.rs.txt"
out="$("$GREP" -F 'clap_builder-4.6.6/src/parser/parser.rs' "$SNAP/MANIFEST.txt" | head -1)"
echo "MANIFEST origin row for parser.rs: $out"
check "C14z the parser.rs snapshot's origin is the published 4.6.6 tarball and its crates.io checksum" \
  "7b48fea5a88e9ae728a2dcbedbfc0e730f7d60da42e1cb049a83c9fb8b789889" "$out"
out="$(sed -n '1322,1331p' "$PR")"
echo "$out"
check "C14a the ArgAction::Version arm begins at parser.rs:1322" \
  "ArgAction::Version => {" "$out"
check "C14b Identifier::Long selects the long rendering" \
  "Some(Identifier::Long) => true," "$out"
check "C14c Identifier::Short selects the short rendering" \
  "Some(Identifier::Short) => false," "$out"
check "C14d the arm RETURNS Err(version_err), so parsing stops there" \
  "Err(self.version_err(use_long))" "$out"
# Inverse control: the arm must not contain an Ok(...) continuation, or the
# short-circuit claim would be wrong in the other direction.
out="$(sed -n '1322,1331p' "$PR" | "$GREP" -c 'Ok(')"
echo "Ok(...) continuations inside the ArgAction::Version arm: $out"
check "C14e the arm has no Ok continuation — it cannot fall through to later args" "count=0" "count=$out"
# And the contrast that proves the check is discriminating: the immediately
# preceding Help arm has the same shape, while the ValuesDone arm just above it
# does return Ok. If this file's Ok( search were broken, this would catch it.
out="$(sed -n '1290,1302p' "$PR" | "$GREP" -c 'Ok(ParseResult::')"
echo "Ok(ParseResult::...) returns in the preceding arms (proves the Ok search works): $out"
check "C14f the Ok search is discriminating, not vacuous" "positive=yes" \
  "positive=$([ "$out" -gt 0 ] && echo yes || echo no)"

echo "=== C15. the four Command version APIs F267's decided mechanism names ==="
while IFS='|' read -r fn ln; do
  [ -z "$fn" ] && continue
  out="$(sed -n "${ln}p" "$CB")"
  printf 'command.rs:%s: %s\n' "$ln" "$out"
  check "C15 Command::$fn at command.rs:$ln" "pub fn $fn" "$out"
done <<'VAPIS'
render_version|1097
disable_version_flag|1493
version|2119
long_version|2151
VAPIS
out="$(sed -n '1097,1099p' "$CB")"
echo "$out"
check "C15a render_version() is _render_version(false) — the SHORT, single-line form" \
  "self._render_version(false)" "$out"
out="$(sed -n '4906,4913p' "$CB")"
echo "$out"
check "C15b the false branch reads self.version first" "self.version" "$out"
check "C15c the rendered string is display-name then version, one line" \
  'format!("{display_name} {ver}\n")' "$out"
out="$(sed -n '1448p' "$CB")"
echo "$out"
check "C15d disable_version_flag is documented as disabling BOTH -V and --version" \
  "Disables \`-V\` and \`--version\` flag." "$out"
out="$(sed -n '1455,1463p' "$CB")"
echo "$out"
check "C15e its doctest asserts --version then yields UnknownArgument" \
  "ErrorKind::UnknownArgument" "$out"
out="$(sed -n '1465,1491p' "$CB")"
echo "$out"
check "C15f clap's own custom-flag recipe uses ArgAction::Version" \
  ".action(ArgAction::Version)" "$out"
check "C15g and therefore still yields DisplayVersion — the trap the decision names" \
  "ErrorKind::DisplayVersion" "$out"
# The decision writes the derive spelling as #[command(disable_version_flag = true)].
# Revision 3 proved the same forwarding for `alias` (C12) because the R1.3 repair
# rested on it; the same proof is owed here, since F267's mechanism rests on this
# one. `disable_version_flag` is not a MagicAttrName either, so it takes the same
# generic branch C12b and C12c already verified and emits
# `.disable_version_flag(true)` — the builder method C15 just located.
out="$("$GREP" -c 'disable_version_flag' "$CD_ATTR")"
echo "occurrences of 'disable_version_flag' in clap_derive's attribute table (attr.rs): $out"
check "C15h 'disable_version_flag' is not a magic attribute name, so it forwards verbatim" "count=0" "count=$out"

echo "=== C16. R66 owns no registry parameter — why no CONFLICT line is raised ==="
# A 'CONFLICT: R66 <param>' line names a consumed registry parameter whose value
# would have to change. Both halves of 'there is no such parameter' are asserted
# as labelled counts, so an absence cannot be confused with a failed search.
R66P="$REPO_ROOT/research/runs/R66/2026-09-05T183458Z-9ff7d91f9b8f/inputs/prompt.md"
out="$([ -f "$R66P" ] && echo present || echo MISSING)"
echo "R66's binding prompt: $out"
check "C16z R66's prompt is in this checkout, so the counts below are real" "present" "$out"
out="$("$GREP" -n '^- owns:' "$R66P")"
echo "R66 prompt owns line: $out"
check "C16a R66's - owns: line is present and EMPTY" "20:- owns:" "$out"
out="$("$GREP" -cE '^- owns: .+' "$R66P")"
echo "R66 owns lines carrying a value: $out"
check "C16b R66 owns no named parameter" "count=0" "count=$out"
out="$("$GREP" -ciE '^\| *(output-format|format-selection|output-file)[a-z-]* *\|' "$REGISTRY")"
echo "output-format rows in docs/port/PARAMETERS.md: $out"
check "C16c the registry carries no output-format parameter for R66 to own" "count=0" "count=$out"
out="$("$GREP" -cE '^\| R66 \|' "$REPO_ROOT/research/CLAUDE.md")"
echo "R66 rows in the research index: $out"
check "C16d R66 has exactly one index row" "count=1" "count=$out"
out="$("$GREP" -E '^\| R66 \|' "$REPO_ROOT/research/CLAUDE.md")"
echo "$out"
check "C16e the index records R66 as owning no parameter" "| — |" "$out"
check "C16f R66 is still open, so its flag spelling is genuinely undecided" "| open |" "$out"
echo "=== C16h-C16n. THE OWNER'S RULING IS RECORDED IN THIS REPOSITORY (was U8) ==="
# REVISION 5 INVERTS REVISION 4's C16h/C16i. Revision 4 asserted the ruling was
# ABSENT from docs/port/OWNER-REVIEW.md and carried that absence as U8. The
# revision-4 audit reran the script after the controller wrote the ruling into
# that file and both checks failed (OV-01 count 3, 2026-09-14 count 1) — the
# audit's finding F1. The claim is now the opposite one and is checked as such.
#
# ANCHORED, NOT COUNTED. docs/port/OWNER-REVIEW.md is the controller's file and
# gains sections over time, so a file-wide count of 'OV-01' would break on the
# next unrelated edit exactly as revision 4's zero broke on this one. The
# ruling's own section is located by its heading, extracted, and each clause this
# decision relies on is asserted INSIDE that extraction. C16m is the control that
# keeps the extraction from silently becoming the whole file.
OR="$REPO_ROOT/docs/port/OWNER-REVIEW.md"
out="$([ -f "$OR" ] && echo present || echo MISSING)"
echo "docs/port/OWNER-REVIEW.md: $out"
check "C16g the owner-review file is in this checkout, so the assertions below are real" "present" "$out"
RULING_HEAD='### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused'
out="$("$GREP" -cF "$RULING_HEAD" "$OR")"
echo "occurrences of the ruling's section heading in docs/port/OWNER-REVIEW.md ($GREP $GREP_VERSION): $out"
check "C16h the ruling has exactly one section in the port's durable record" "count=1" "count=$out"
# Extract that section: from its heading up to the next H2, which is '## Dispositions'.
RULING="$(sed -n '/^### 2026-09-14 — the CLI Design Standard binds/,/^## /p' "$OR")"
# A threshold, not the line count itself: the count is a number in a file this
# item does not own, and printing it would make this log stop matching the moment
# the controller reworded a sentence. What has to be true is that the extraction
# is a section rather than an empty string.
ruling_lines="$(printf '%s' "$RULING" | wc -l | tr -d ' ')"
echo "the extracted ruling section is more than ten lines long: $([ "$ruling_lines" -gt 10 ] && echo yes || echo no)"
check "C16h2 the extraction is non-empty, so the clause checks below read real text" "yes" \
  "$([ "$ruling_lines" -gt 10 ] && echo yes || echo no)"
echo "--- the clauses this decision relies on, each asserted inside that section ---"
check "C16i it binds the same pinned standard revision this decision records" \
  "(version 1.4.14, blob \`f9de0437\`) governs this template" "$RULING"
check "C16j OV-01 is REFUSED" "**Override OV-01 is REFUSED.**" "$RULING"
check "C16k the owner selected R60's own conformant option (b)" \
  "The owner instead selected R60's own conformant option (b)" "$RULING"
check "C16k2 extended build data moves behind a JSON output flag" \
  "extended build data moves behind a" "$RULING"
check "C16l the template waives no SHOULD" \
  "**Consequence for conformance: the template waives no \`SHOULD\`.**" "$RULING"
check "C16l2 and R60 carries zero overrides, OV-01 retired rather than deleted" \
  "R60 carries zero overrides; OV-01 is retired as" "$RULING"
# THE EXTRACTION CONTROL. 'Zero license check' is the owner's 2026-09-12 licence
# ruling, which lives in a DIFFERENT section of the same file. If the sed range
# above ever widened to the whole file, this string would appear inside $RULING
# and the clause checks above would stop meaning 'inside the 2026-09-14 section'.
out="$(printf '%s' "$RULING" | "$GREP" -cF 'Zero license' || true)"
echo "occurrences of the 2026-09-12 section's text inside the extraction: $out"
check "C16m control: the extraction really is scoped to the 2026-09-14 section" "count=0" "count=$out"
# The second durable record: the reasoning and blast radius, in the planning file
# the port record itself points at. Two '## 9.' headings exist in that file — the
# original ask and the ANSWERED disposition — so the ANSWERED one is named exactly.
OD="$REPO_ROOT/docs/planning/p02/owner-decisions.md"
out="$([ -f "$OD" ] && echo present || echo MISSING)"
echo "docs/planning/p02/owner-decisions.md: $out"
check "C16n the owner-decisions file is in this checkout" "present" "$out"
ANS_HEAD='## 9. Whether your CLI Design Standard binds this port -- ANSWERED 2026-09-14'
out="$("$GREP" -cF "$ANS_HEAD" "$OD")"
echo "occurrences of the ANSWERED section heading ($GREP $GREP_VERSION): $out"
check "C16n2 the answered section exists exactly once" "count=1" "count=$out"
ANSWER="$(sed -n '/^## 9\. Whether your CLI Design Standard binds this port -- ANSWERED/,/^## 9\. Whether your CLI Design Standard binds this port$/p' "$OD")"
check "C16n3 it records the decision in the owner's own words" \
  "**DECIDED.** The standard BINDS. Override OV-01 is NOT waived; the owner" "$ANSWER"
check "C16n4 and that R60's own conformant option (b) was selected" \
  "selected R60's own conformant option (b)." "$ANSWER"
# FILE-WIDE COUNTS ARE DELIBERATELY NEITHER ASSERTED NOR PRINTED, and the reason
# is the whole point of this revision. Revision 4 asserted `OV-01` count 0 and
# `2026-09-14` count 0 over this file; the controller then wrote the ruling and
# both became wrong. Between that audit and this revision the same file gained a
# further section ('## Wave 0 owner acceptances'), moving the `2026-09-14` count
# again — from the 1 the auditor observed to 3. A number read out of a file this
# item does not own is not a stable assertion and is not a stable log line, so
# neither is recorded here; the clause checks above are anchored instead.
# Anchored the same way, and for the same reason: this file grew a second table
# ('## Wave 0 owner acceptances') after the revision-4 audit ran, so a file-wide
# R60 row count is not a stable assertion either. The Dispositions section is
# extracted and the row is counted inside it.
DISPOS="$(sed -n '/^## Dispositions/,$p' "$OR")"
out="$(printf '%s\n' "$DISPOS" | "$GREP" -cE '^\| R60 \|' || true)"
echo "R60 rows inside the Dispositions section ($GREP $GREP_VERSION): $out"
check "C16o R60 still has exactly one dispositions row, unchanged by the ruling" "count=1" "count=$out"
out="$(printf '%s\n' "$DISPOS" | "$GREP" -E '^\| R60 \|')"
echo "$out"
check "C16o2 and it is still the 2026-09-04 codesign acceptance, untouched" \
  "Effect: none; runs as written." "$out"

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
