#!/usr/bin/env bash
# R81 docs-delivery-model — revision-5 claim verification (checks 19 and 20).
#
# This is a NEW script, not an edit of `docs-delivery-claims.sh` or of
# `docs-delivery-claims-r4.sh`. Both of those, and their logs, are earlier
# revisions' artifacts that prior audits reproduced, and both are left untouched;
# check 20 asserts all four by sha256.
#
# Why a new script at all: check 17 (in the r4 script) asserts that the title
# names revision 4 and gates the whole-file revision-3-to-live hunk count at 17.
# A revision 5 moves both by construction, exactly as revision 4 moved check 16's
# `unproven entry 3` end anchor. The handling is the one revision 4 chose: leave
# the old script and its log as history, disclose what the old script now prints
# FROM A RUN, and add a new script that re-targets the same mechanism one blob
# forward. What revision 5 adds is:
#
#   check 19 — the revision-5 diff against the revision-4 blob. It carries every
#              region assertion check 17 made: check 17's twenty-six preservation
#              regions on their check-17 anchors (including `unproven entry 3` on
#              the looser end marker `4. **Wh`, which is the re-anchoring finding
#              J4 required the decision to record), PLUS the eight regions check
#              17 required revision 4 to CHANGE, which revision 5 must now leave
#              alone. It also asserts the three regions this revision does change,
#              and the texts J4 requires present or gone.
#   check 20 — the evidence artifacts revision 5 preserves, asserted by sha256 —
#              check 18's seven plus the r4 script and its log — and a re-read of
#              the fitness-gate-5 async-runtime facts from the committed lock, so
#              those five figures stay gated by a script that exits 0.
#
# Both checks are OFFLINE and deterministic: no network, no gh, no curl. Nothing
# is written inside review/evidence/ — the revision-4 blob goes to a mktemp
# directory that is removed on exit — so a rerun cannot disturb
# review/evidence/snapshots/. That is not hypothetical: rerunning the OLD script
# for this revision rewrote three files under that directory in an isolated clone.
#
# Run from the run directory:
#   research/runs/R81/2026-09-05T183003Z-c02279aa76ae
#   bash review/evidence/docs-delivery-claims-r5.sh > review/evidence/docs-delivery-claims-r5.log 2>&1
#
# PRECONDITION (inherited from checks 16 and 17): $REPO_ROOT must be a git
# checkout whose object database contains blob
# ec356a0d8492a349292807db6cf888aac53619a1 (the revision-4 DECISION.md). A run
# from a plain file copy with no .git cannot read it: check 19 reports FAIL and
# the script exits 1.
set -u
set -o pipefail

REPO_ROOT=$(cd "$(dirname "$0")/../../../../../.." && pwd)
EV=$(cd "$(dirname "$0")" && pwd)
DEC="$EV/../DECISION.md"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/r81-r5.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
FAILS=0

say()  { printf '%s\n' "$*"; }
hdr()  { printf '\n=== %s ===\n' "$*"; }
assert() { # assert <label> <expected> <actual>
  if [ "$2" = "$3" ]; then printf 'PASS  %-58s %s\n' "$1" "$3"
  else printf 'FAIL  %-58s expected=%s actual=%s\n' "$1" "$2" "$3"; FAILS=$((FAILS+1)); fi
}

# ---------------------------------------------------------------- check 19
hdr "check 19 — revision-5 diff against the revision-4 blob"
R4BLOB=ec356a0d8492a349292807db6cf888aac53619a1
git -C "$REPO_ROOT" cat-file blob "$R4BLOB" > "$TMP/decision-r4.md" 2>/dev/null
assert "revision-4 blob read exit" "0" "$?"
assert "revision-4 blob sha256" "ebcbe236064e05558895d2acc2ee5f6b7f9a6c712f6527c76c9fb92fdeecbf51" \
  "$(shasum -a 256 "$TMP/decision-r4.md" | awk '{print $1}')"
assert "revision-4 blob is non-empty" "yes" \
  "$([ -s "$TMP/decision-r4.md" ] && echo yes || echo no)"
assert "revision-5 decision file present" "yes" \
  "$([ -s "$DEC" ] && echo yes || echo no)"

python3 - "$TMP/decision-r4.md" "$DEC" <<'PY'
import sys, difflib
r4=open(sys.argv[1]).read().splitlines(True); r5=open(sys.argv[2]).read().splitlines(True)
def region(lines,start,ends):
    # ends == [] means "to the end of the file"; otherwise the region stops at
    # the first line starting with any end marker, and a missing end marker is a
    # failure rather than a silent whole-file read.
    i=[k for k,l in enumerate(lines) if l.startswith(start)]
    if not i: return None
    i=i[0]
    out=lines[i:] if not ends else None
    if ends:
        for k in range(i+1,len(lines)):
            if any(lines[k].startswith(e) for e in ends): out=lines[i:k]; break
    if out is None: return None
    while out and not out[-1].strip(): out.pop()   # trailing blank lines are not content
    return out
# ---------------------------------------------------------------------------
# A. Regions revision 5 must NOT have touched. The judgment audit rejected
#    revision 4 on ONE finding about how the decision reports its own evidence and
#    stated that the recommendation, the crate, the version, the corpus figures,
#    the notice rule, the gate block, the confidence statement and every evidence
#    artifact are untouched by it. So every region check 17 asserted is asserted
#    here — the twenty-six it preserved AND the eight it required revision 4 to
#    change, which are now preservation targets in their own right.
# ---------------------------------------------------------------------------
REGIONS=[
 # -- check 17's twenty-six preservation regions, on their check-17 anchors ----
 ("licence partition table",       "| Class | Count | Packages",                  ["\n"]),
 ("what each class means",         "**What each class means for the fixed",       ["**None of these 218"]),
 ("shared requirement -> what may vary",
                                   "**Shared requirement, its source and agreement level.**",
                                                                                  ["**Architectural alternatives compared"]),
 ("the four fixed - assumes lines","- assumes msrv-policy",                       ["\n"]),
 ("check-8 snapshot rationale",    "**How check 8 avoids lying about a rate-limited sweep.**",
                                                                                  ["**Nothing recommended was implemented.**"]),
 ("revision-1 check-defect record","Three assertions failed on revision 1's first run",
                                                                                  ["| # | Check |"]),
 ("disagreement 4 (figures)",      "**Disagreement 4 — the mdBook MSRV and figure set.**",
                                                                                  ["**Unproven, with what would prove it.**"]),
 # the re-anchored region J4 is about: the looser end marker is the one thing
 # that lets this assertion still be evaluated at all.
 ("unproven entry 3 (unsafe posture), on the re-anchored end marker",
                                   "3. **mdBook's `unsafe` posture**",            ["4. **Wh"]),
 ("revision-1 history entry",      "- **Revision 1**, 2026-09-10, sha256",        ["- **Revision 2**"]),
 ("revision-3 note, opening (the recommendation change)",
                                   "**Revision note — the recommendation changed",["**What the ruling does not touch"]),
 ("revision-3 note, candidates re-entering on fit",
                                   "Two candidates that revision 2 weighed partly on licence",
                                                                                  ["No `## Supersedes` section is present"]),
 ("the ledger decision table",     "| Ledger row | Decision |",                   ["\n"]),
 ("the generator layer is four artifacts",
                                   "**The generator layer is four artifacts",     ["**The fit judgement"]),
 ("the theme/ rule",               "**The `theme/` rule, which the ruling explicitly preserves.**",
                                                                                  ["**Ledger rows settled**"]),
 ("ledger rows settled",           "**Ledger rows settled**",                     ["**Baseline-review lines.**"]),
 ("BASELINE-REVIEW F357 line",     "BASELINE-REVIEW: F357",                       ["\n"]),
 ("BASELINE-REVIEW F358 line",     "BASELINE-REVIEW: F358",                       ["\n"]),
 ("minimal realistic example",     "**Minimal realistic example",                 ["re-verify:"]),
 ("re-verify line",                "re-verify:",                                  ["\n"]),
 ("the whole ## Parameters section","## Parameters",                              ["## Empirical check"]),
 ("the 16-row check table",        "| # | Check | Command | Exit | Result | Log |",["\n"]),
 ("the gated-count paragraph",     "`set -o pipefail` is set at the top of the script",
                                                                                  ["**The distinction between a gate"]),
 ("reproducibility paragraph",     "**Reproducibility.**",                        ["## Engines"]),
 ("disagreements 2 and 3",         "**Disagreement 2 — Zola's standing.**",       ["**Disagreement 4"]),
 ("revision-2 history entry",      "- **Revision 2**, 2026-09-12, sha256",        ["- **Revision 3**"]),
 ("revision-3 history entry, body","  of 2026-09-12 (Q4 as superseded by Q7.B), not by an audit finding",
                                                                                  ["- **Revision 4**","**Uncertainty.**"]),
 # -- the eight regions check 17 required revision 4 to CHANGE. J4 touches none
 #    of them, so revision 5 must leave every one byte-identical. ------------
 ("J1 repair: the shipped-site notice rule",
                                   "**None of these 218 packages is linked",      ["**The generator slot:"]),
 ("J1 repair: gap 4 widened to every emitted asset",
                                   "4. **Wh",                                     ["5. **Wall-clock and byte cost**"]),
 ("J2 repair: the six-gate block", "**Fitness gate 1** is recorded",
                                                                                  ["**The facts below are retained as findings"]),
 ("J3 repair: ground 2 narrowed to the surveyed sample",
                                   "2. **The corpus this template is required to carry",
                                                                                  ["3. **It restores a capability"]),
 ("J3 repair: the confidence statement",
                                   "**What weighs against, and why it does not win.**",
                                                                                  ["**Fitness gate 1** is recorded"]),
 ("J3 repair: the runner-up's cost list",
                                   "- **No generator at all**",                   ["- **`zola`**"]),
 ("J3 repair: disagreement 1 names the sample",
                                   "**Disagreement 1 — ship a generator",         ["**Disagreement 2"]),
 ("J3 repair: the uncertainty entry (to end of file)",
                                   "**Uncertainty.**",                            []),
 # -- regions this revision adds to the preservation set --------------------
 ("the revision-4 note, kept verbatim as history",
                                   "**Revision note (revision 4) — three recorded repairs",
                                                                                  ["**Revision note — the recommendation changed"]),
 ("the check-18 table row",        "| 18 | Preserved artifacts",                  ["| 19 |","\n"]),
 ("revision-4 history entry, body","  change**, and neither did the crate, the version, the ledger-row values, the",
                                                                                  ["- **Revision 5**","**Uncertainty.**"]),
]
bad=0
for name,start,ends in REGIONS:
    a,b=region(r4,start,ends),region(r5,start,ends)
    if a is None or b is None:
        print("FAIL  region marker not found: %-52s r4=%s r5=%s"%(name,a is not None,b is not None)); bad+=1
    elif a==b:
        print("PASS  region byte-identical to revision 4: %-48s %d lines"%(name,len(a)))
    else:
        print("FAIL  region CHANGED: %s"%name); bad+=1
        for l in a:
            if l not in b: print("        r4-only: %s"%l.rstrip()[:120])
# ---------------------------------------------------------------------------
# B. The three regions finding J4 requires revision 5 to change: asserted to have
#    changed AND to carry the sentence that shows they were changed for the right
#    reason. The start markers differ between r4 and r5 where the heading itself
#    is what changed.
# ---------------------------------------------------------------------------
CHANGED_BY_FINDING=[
 ("J4 — the disclosure paragraph is rewritten from a run",
  "**What revision 4 ran, what it did not run",
  "**What revision 5 ran, what it did not run",
  ["| # | Check | Command"],
  "FAIL  region marker not found: unproven entry 3 (unsafe posture)"),
 ("J4 — check 17's table row records the re-anchoring",
  "| 17 | Revision-4 diff against the revision-3 blob",
  "| 17 | Revision-4 diff against the revision-3 blob",
  ["| 18 |"],
  "**unproven entry 3 re-anchored**"),
 ("the revision-4 history entry gains its sha256",
  "- **Revision 4**, 2026-09-15, this document",
  "- **Revision 4**, 2026-09-15, sha256",
  ["  change**, and neither did the crate, the version, the ledger-row values, the"],
  "ebcbe236064e05558895d2acc2ee5f6b7f9a6c712f6527c76c9fb92fdeecbf51"),
]
for name,s4,s5,ends,frag in CHANGED_BY_FINDING:
    a,b=region(r4,s4,ends),region(r5,s5,ends)
    if a is None or b is None:
        print("FAIL  finding region marker not found: %-40s r4=%s r5=%s"%(name,a is not None,b is not None)); bad+=1; continue
    if a==b:
        print("FAIL  finding region NOT updated (still revision-4 text): %s"%name); bad+=1
    elif frag in "".join(b):
        print("PASS  finding region updated and carries its marker: %s"%name)
    else:
        print("FAIL  finding region changed but lacks its marker: %s  [%s]"%(name,frag)); bad+=1
# ---------------------------------------------------------------------------
# C. Text revision 5 must carry, and text finding J4 requires it to have dropped.
#    Everything check 17 required is carried forward, so those requirements
#    cannot lapse behind a new script.
# ---------------------------------------------------------------------------
whole5="".join(r5)
MUST_CARRY=[
 # ---- carried forward verbatim from check 17 (and through it from check 16) --
 ("gate 1 recorded on one line, verbatim",
  "`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`"),
 ("the theme/ prohibition survives the ruling", "never commit a `theme/` directory"),
 ("the Font Awesome duty sentence is preserved, not deleted",
  "attribution owed for icon\nassets in the built site"),
 ("no surveyed licence reaches the template's own source",
  "none of them\nreaches the template's own `MIT OR Apache-2.0` source"),
 ("mermaid fences are forbidden by F343", "` ```mermaid ` fences"),
 ("no adopter of the exact Pages-action majors is claimed",
  "not the `v6.0.0`/`v5.0.0`/`v5.0.1`\n   majors `opus` recommends"),
 ("no local renderer matches the host's dialect",
  "no local renderer reproducing GitHub's exact Markdown semantics\n   was identified"),
 ("identical rendering rests on inspection",
  "**Identical rendering on both surfaces is inspected, not verified.**"),
 ("the measured corpus figure", "**35 `.md` files totalling 171,225 bytes**"),
 ("the per-category tallies", "`tutorials` 2, `reference` 5, `contributing` 6"),
 ("the licence partition arithmetic", "`218 = 8 + 4 + 2 + 8 + 196`"),
 ("J1 the rule is named and reachable", "**The shipped-site notice rule**"),
 ("J1 the two acts are separated", "two different acts"),
 ("J1 elasticlunr is disposed of explicitly", "`elasticlunr-rs` is the case that makes the asymmetry"),
 ("J1 crate metadata cannot enumerate emitted files",
  "is not a list of the third-party files that crate"),
 ("J1 no asset list is asserted", "asserts nothing about which files a built"),
 ("J2 the gates block exists", "**Fitness gates, answered for the recommended tool.**"),
 ("J2 gate 2 recorded", "**Gate 2 (crate and dependency-tree MSRV).**"),
 ("J2 gate 3 recorded", "**Gate 3 (open advisories; `unsafe` posture).**"),
 ("J2 gate 4 recorded", "**Gate 4 (builds and is tested on `ubuntu-latest, macos-latest`).**"),
 ("J2 gate 5 recorded", "**Gate 5 (default features and any async-runtime coupling).**"),
 ("J2 gate 6 recorded", "**Gate 6 (binary-size and compile-time cost, qualitatively).**"),
 ("J2 gate 5 resolves the contributor install line",
  "neither body passes a feature\n  flag, so both take mdBook's **default** features"),
 ("J2 gate 5 declines the trimming flag pair",
  "is therefore not this\n  template's install line**"),
 ("gate 3 claims no checksum asset that does not exist",
  "there is no published checksum asset to verify against"),
 ("the revision-3 history entry carries its sha256",
  "- **Revision 3**, 2026-09-13, sha256\n  `4647372666b7e94537d75fb684c6ca5ec5cca6929841330bab8832ddb6e7328e`."),
 ("J2 gate 5 states the async runtime is confined", "`tokio-tungstenite` 0.29.0 (check 18)"),
 ("J2 gate 5 frees R05 and R69", "are therefore unconstrained by this item"),
 ("J2 the serve claim is recorded as unproven", "unproven entry 7"),
 ("J3 rustup is used, with its path", "doc/user-guide/book.toml"),
 ("J3 the adopters are marked carried, not re-verified",
  "carried from `opus`'s raw rather than re-verified"),
 ("J3 the opus endpoint is cited",
  "`GET https://api.github.com/repos/<o>/<r>/contents/<path>`"),
 ("J3 what would raise the confidence", "**What would raise this above medium, and what would show it wrong.**"),
 ("J3 the P03 signal that would show it wrong", "*Showing it wrong in P03.*"),
 # ---- new for J4: the disclosure must be quotable back to a run --------------
 ("J4 the old script's failing region assertion is quoted verbatim",
  "FAIL  region marker not found: unproven entry 3 (unsafe posture)      r2=True r3=False"),
 ("J4 the shell assertion it sets is quoted verbatim",
  "FAIL  revision-3 untouched-region diff                           expected=0 actual=1"),
 ("J4 the hunk-count tripwire is recorded as still PASSING",
  "still prints\n`ASSERT hunk_count_is_17=True`"),
 ("J4 the old script's PASS/FAIL tallies are recorded",
  "**152 `PASS` lines — 119 in checks 1–15 and 33 in check 16 — 2 `FAIL` lines, and\n`failed assertions: 1`**"),
 ("J4 the broken end anchor is named with its script line",
  "`\"4. **Whether mdBook\"`\n(`review/evidence/docs-delivery-claims.sh:514`)"),
 ("J4 the cause is named as an anchor, not a line count",
  "The cause is an end anchor, not a line count"),
 ("J4 the re-anchoring is recorded in prose, with its script line",
  "`\"4. **Wh\"`\n(`review/evidence/docs-delivery-claims-r4.sh:98`)"),
 ("J4 the empirical audit's concurring sentence is quoted",
  "the changed-region assertion is the direct failure."),
 ("J4 the r4 script and log are preserved as history",
  "are left **byte-identical** as the\nrecord of the revision-4 run"),
 ("the revision-4 history entry carries its sha256",
  "- **Revision 4**, 2026-09-15, sha256\n  `ebcbe236064e05558895d2acc2ee5f6b7f9a6c712f6527c76c9fb92fdeecbf51`."),
 ("the new script is named", "`review/evidence/docs-delivery-claims-r5.sh`"),
 ("the revision-4 blob is named", "`ec356a0d8492a349292807db6cf888aac53619a1`"),
]
for name,frag in MUST_CARRY:
    if frag in whole5: print("PASS  present verbatim: %s"%name)
    else: print("FAIL  required text MISSING: %s  [%r]"%(name,frag[:60])); bad+=1
# The live decision runs from "## Decision" to "**Revision history.**": the
# revision notes above it legitimately QUOTE the findings they repair, and the
# history legitimately describes what earlier revisions said.
start=whole5.index("## Decision"); cut=whole5.index("**Revision history.**")
live=whole5[start:cut]
MUST_NOT_CARRY=[
 # ---- J4's own removals: the false mechanism and the overstatement ----------
 ("the false causal clause about check 16's failure",
  "Revision 4's edits are exactly such a change"),
 ("the wrong attribution of the failure to the hunk-count gate",
  "gates the whole-file hunk count at\nexactly 17, a tripwire"),
 ("the overstated claim about what check 17 carries",
  "carries every region assertion"),
 ("the mis-cited snapshot-emptying rerun",
  "the way the concurrent shared-directory rerun"),
 # ---- carried forward from check 17 ----------------------------------------
 ("the overreaching practice claim (ground 2)", "Rust practice splits on exactly that"),
 ("the overreaching practice claim (disagreement 1)", "Rust practice splitting on exactly that"),
 ("the runner-up's contradicted sentence", "gains nothing in"),
 ("the alternative-(B) version of it", "paying those costs buys nothing"),
 ("branch vocabulary A", "branch A"), ("branch vocabulary B", "branch B"),
 ("branch vocabulary A (capitalised)", "Branch A"), ("branch vocabulary B (capitalised)", "Branch B"),
 ("branch vocabulary hyphenated A", "branch-A"), ("branch vocabulary hyphenated B", "branch-B"),
 ("two-branch vocabulary", "two-branch"),
]
for name,frag in MUST_NOT_CARRY:
    n=live.count(frag)
    if n==0: print("PASS  absent from the live decision: %s"%name)
    else: print("FAIL  still in the live decision: %s (%r x%d)"%(name,frag,n)); bad+=1
if "branch" in whole5[cut:]: print("PASS  revision history still describes the branch structure")
else: print("FAIL  revision history no longer describes the branch structure"); bad+=1
if not any(l.startswith("## Supersedes") for l in r5): print("PASS  no ## Supersedes heading")
else: print("FAIL  ## Supersedes heading present"); bad+=1
if any(l.startswith("# R81") and "revision 5" in l for l in r5): print("PASS  title names revision 5")
else: print("FAIL  title does not name revision 5"); bad+=1
if any(l.startswith("- **Revision 5**") for l in r5): print("PASS  revision history carries a revision-5 entry")
else: print("FAIL  revision history has no revision-5 entry"); bad+=1
hunks=[l for l in difflib.unified_diff(r4,r5,n=3) if l.startswith('@@')]
print("whole-file unified-diff hunks: %d"%len(hunks))
for h in hunks: print("      %s"%h.strip())
EXPECTED_HUNKS=4
if len(hunks)==EXPECTED_HUNKS: print("ASSERT r5_hunk_count_is_%d=True"%EXPECTED_HUNKS)
else: print("ASSERT r5_hunk_count_is_%d=False actual=%d"%(EXPECTED_HUNKS,len(hunks))); bad+=1
sys.exit(1 if bad else 0)
PY
assert "revision-5 region and text diff" "0" "$?"

# ---------------------------------------------------------------- check 20
# Two jobs. (a) Prove that every evidence artifact the earlier audits read is
# byte-identical under revision 5 - revision 5 re-researches nothing, so a changed
# artifact would be a defect. The list is check 18's seven PLUS the revision-4
# script and log, which revision 5 preserves as history for exactly the reason
# revision 4 preserved revision 3's pair. (b) Re-read fitness gate 5's
# async-runtime facts out of the committed lock, so the gate-5 answer in
# `## Decision` stays failure-gated by a script that exits 0 rather than by the r4
# script, which now exits 1 by construction.
hdr "check 20 — preserved evidence artifacts, and the gate-5 facts in the committed lock"
while IFS='|' read -r f want; do
  got=$(shasum -a 256 "$EV/$f" 2>/dev/null | awk '{print $1}')
  assert "unchanged: $f" "$want" "${got:-MISSING}"
done <<'EOF'
docs-delivery-claims.sh|c2c69fb47e36792a56813b86de41e66ea49d78bea092abbf55c077202747a63c
docs-delivery-claims.log|152ddb42429b3b72646cb24bf9fd6d5cd103adb099784a7865630a6fbeb0981c
docs-delivery-claims-r4.sh|ba915596e5cfc7bc9b8355f9781101d5eb9267cbf634061257fd24b854cc0a34
docs-delivery-claims-r4.log|2ca46e1812beb805e89c52db8e5d1b89c8fac1fdb23c9e3549b1948be1a75c4a
audit-docs-delivery-model-r1.log|6d8da82b7b814743ce9ffc0c641e84968849d7da53a0fb42107601e2c87f9a7e
audit-docs-delivery-model-r2.log|2da86bff14dde7678e93bd642e9219ca90ef26e4f5f6bf26234556c3c3975216
audit-docs-delivery-model-r3.log|152ddb42429b3b72646cb24bf9fd6d5cd103adb099784a7865630a6fbeb0981c
audit-docs-delivery-model-r4.log|2ca46e1812beb805e89c52db8e5d1b89c8fac1fdb23c9e3549b1948be1a75c4a
mdbook-0.5.4-Cargo.lock|0fa8a0e93acfcf6a93f39df0c091b961abd04d36bbebf8c725e75ffac4a2abc4
mdbook-0.5.4-licences.json|f4afe93fe5b7d487d9efa943c79900aa1346add9e7195f4f3d8045afb8a266b9
EOF

lockver() { # lockver <package> -> the version Cargo locked for it, or NONE
  python3 - "$EV/mdbook-0.5.4-Cargo.lock" "$1" <<'PY'
import sys,re
t=open(sys.argv[1]).read(); want=sys.argv[2]
for blk in t.split("[[package]]"):
    m=re.search(r'^name = "(.+?)"$',blk,re.M); v=re.search(r'^version = "(.+?)"$',blk,re.M)
    if m and m.group(1)==want: print(v.group(1) if v else "NOVERSION"); break
else: print("NONE")
PY
}
# Gate 5: mdBook's own serve path carries an async stack. These three are the
# evidence for "confined to mdBook's own process"; none of them is in this
# template's Cargo.toml, which is the point the gate makes.
assert "gate 5: tokio locked in mdBook's own tree"             "1.53.1" "$(lockver tokio)"
assert "gate 5: axum locked in mdBook's own tree"              "0.8.9"  "$(lockver axum)"
assert "gate 5: tokio-tungstenite locked in mdBook's own tree" "0.29.0" "$(lockver tokio-tungstenite)"
# J1: the two packages the shipped-site notice rule reasons about are in that
# same tree, at the versions `## Decision` names.
assert "J1: font-awesome-as-a-crate in mdBook's own tree" "0.3.1" "$(lockver font-awesome-as-a-crate)"
assert "J1: elasticlunr-rs in mdBook's own tree"          "3.1.0" "$(lockver elasticlunr-rs)"
# A control: a package that is NOT in the tree must report NONE, so the reader
# above can fail rather than always finding something.
assert "control: a package absent from the tree reports NONE" "NONE" "$(lockver no-such-crate-xyzzy)"

hdr "result"
say "failed assertions: $FAILS"
[ "$FAILS" -eq 0 ] || exit 1
exit 0
