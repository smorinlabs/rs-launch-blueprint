#!/usr/bin/env bash
# R76 empirical check, part 3 of 3: assert the decision document's own
# structural obligations, the ones a reader cannot verify by reading.
#
# Everything here reads files inside this run's directory or the repository's
# parameter registry. It reaches no network, needs no `.git`, and therefore
# runs unchanged from a clean `git archive HEAD` extraction. Section G also
# reads the py-launch-blueprint clone at PY_REPO (overridable) at its pin, and
# skips by name when that clone is absent.
#
# Revision 3 (2026-09-27) re-targeted this script at revision 3 of the
# decision: the title line, an engine record for both raw reports (Muse and
# Opus) instead of revision 2's single-engine record, the re-measured figures,
# and a new section G that resolves every path:line citation in the document.
#
# Revision 5 (2026-09-27) re-targeted it at revision 5: the title line, and
# the web-extra-surface flag day (owner ruling W1-R02, owner decision Q3.A).
# That one '- assumes' line is compared with R69 revision 11's '- owns' line
# at line 1885 (sha256-pinned), not with the registry row, which still holds
# R69 revision 9's bytes until R69 republishes.
#
# Line prefixes:
#   ASSERT  — a content assertion. `ASSERT FAIL` sets exit status 1.
#   SKIP    — a check that could not run, with the reason named.

set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "$0")" && pwd)"
REVIEW="$(cd "$HERE/.." && pwd)"
RUN="$(cd "$REVIEW/.." && pwd)"
DEC="$REVIEW/DECISION.md"
RAW="$RUN/raw/opus.md"
MUSE="$RUN/raw/muse.md"
PY_REPO="${PY_REPO:-/Users/stevemorin/c/py-launch-blueprint}"
PY_PIN=b08bccfb
# research/runs/R76/<run>/ -> repository root is five levels up.
ROOT="$(cd "$RUN/../../../.." && pwd)"
REG="$ROOT/docs/port/PARAMETERS.md"

echo "=== R76 decision self-check ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $("$GREP" --version | head -1)"
echo "decision:  $DEC"
if [ -f "$DEC" ]; then echo "decision sha256: $(shasum -a 256 "$DEC" | cut -d' ' -f1)"; fi
echo "raw:       $RAW"
echo "registry:  $REG"
echo

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r76-selfcheck.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass=0; failn=0; skipn=0
assert() {
  if [ "$1" = "1" ]; then echo "ASSERT ok   $2"; pass=$((pass + 1))
  else echo "ASSERT FAIL $2"; failn=$((failn + 1)); fi
}
skip() { echo "SKIP        $1"; skipn=$((skipn + 1)); }
eq() { if [ "$1" = "$2" ]; then echo 1; else echo 0; fi; }
countF() { "$GREP" -cF -- "$1" "$2" || true; }

if [ ! -f "$DEC" ]; then
  skip "everything: DECISION.md is absent, so nothing about it could be checked"
  echo; echo "=== RESULT ==="
  echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
  echo "RESULT: PASS (nothing ran)"; exit 0
fi

# ---------------------------------------------------------------------------
echo "--- A. the document's shape, which the revision rules fix exactly ---"
H1=$(head -1 "$DEC")
echo "H1: ${H1}"
assert "$(eq "$H1" '# 2026-09-27 — R76 — cors-middleware (crate, Focused) — decision (revision 5)')" \
  "the H1 is the date-first form the revision rules require, naming the item, kind, tier and revision"
H2S=$("$GREP" '^## ' "$DEC" | tr '\n' '|')
echo "H2 headings: ${H2S}"
assert "$(eq "$H2S" '## Decision|## Parameters|## Empirical check|## Engines|')" \
  "the four required H2 sections appear exactly once each, in the required order, and no other H2 was added"
# These are anchored at line start on purpose: an unanchored search would also
# match this document describing its own headings in prose.
assert "$(eq "$("$GREP" -c '^## Supersedes' "$DEC" || true)" "0")" \
  "no Supersedes section heading: revision 3 reverses nothing, so the rules say it must not carry one"
assert "$(eq "$("$GREP" -c '^### Principles and implementation' "$DEC" || true)" "1")" \
  "the Decision section carries its one required H3 heading, exactly once"
assert "$(eq "$("$GREP" -c '^### OVERRIDE (OV-08) — ' "$DEC" || true)" "1")" \
  "and one OVERRIDE (OV-08) heading, the written R4.17 preflight deviation, exactly once"
N=$("$GREP" -c '^re-verify:' "$DEC" || true)
RVLINE=$("$GREP" -n '^re-verify:' "$DEC" | cut -d: -f1 | head -1)
PARAMLINE=$("$GREP" -n '^## Parameters' "$DEC" | cut -d: -f1 | head -1)
echo "trigger line at ${RVLINE:-none}; Parameters heading at ${PARAMLINE:-none}"
assert "$(eq "$N" "1")" "exactly one line begins with the re-verify marker, which is the rule"
assert "$(if [ -n "$RVLINE" ] && [ -n "$PARAMLINE" ] && [ "$RVLINE" -lt "$PARAMLINE" ]; then echo 1; else echo 0; fi)" \
  "and it is the closing line of the Decision section rather than floating elsewhere in the document"
assert "$(eq "$("$GREP" -c '^re-verify: on the earlier of 2027-03-27' "$DEC" || true)" "1")" \
  "that line carries a dated horizon as well as its event triggers"
echo

# ---------------------------------------------------------------------------
echo "--- B. the parameter lines, compared byte-for-byte with the live registry ---"
if [ ! -f "$REG" ]; then
  skip "B: docs/port/PARAMETERS.md is not reachable from this extraction, so the parameter bytes were not compared"
else
  R69DEC="$ROOT/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
  R69SHA=2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815
  if [ -f "$R69DEC" ]; then R69GOT=$(shasum -a 256 "$R69DEC" | cut -d' ' -f1); else R69GOT=absent; fi
  assert "$(eq "$R69GOT" "$R69SHA")" \
    "R69 revision 11's decision is present at sha256 $R69SHA, the flag-day source of the web-extra-surface value"
  python3 - "$REG" "$R69DEC" > "$WORK/registry-lines.txt" <<'PY'
import sys
want = ["web-extra-surface", "error-taxonomy-exit-codes",
        "msrv-policy", "rust-edition", "target-os-matrix", "license"]
rows = {}
for line in open(sys.argv[1], encoding="utf-8"):
    if not line.startswith("| "):
        continue
    cells = line.rstrip("\n").split(" | ")
    if len(cells) < 5:
        continue
    name = cells[0][2:].strip()
    if name in want:
        rows[name] = cells[3]
# Flag day (W1-R02, Q3.A): web-extra-surface comes from R69 revision 11's
# owned line 1885, prefix-swapped; the registry row republishes later.
owns = "- owns web-extra-surface = "
line = open(sys.argv[2], encoding="utf-8").read().split("\n")[1884]
assert line.startswith(owns), "R69 line 1885 is not its owns line"
rows["web-extra-surface"] = line[len(owns):]
for n in want:
    print("- assumes %s = %s" % (n, rows[n]))
PY
  "$GREP" '^- assumes ' "$DEC" > "$WORK/decision-lines.txt"
  echo "registry rows extracted: $(wc -l < "$WORK/registry-lines.txt" | tr -d ' ')"
  echo "assumes lines in the decision: $(wc -l < "$WORK/decision-lines.txt" | tr -d ' ')"
  if diff -u "$WORK/registry-lines.txt" "$WORK/decision-lines.txt" > "$WORK/paramdiff.txt" 2>&1; then
    assert 1 "every '- assumes' line is byte-identical to its source, in the same order: web-extra-surface to R69 revision 11's '- owns' line 1885 (flag day, registry row pending republication), the other five to their docs/port/PARAMETERS.md rows"
  else
    echo "--- diff registry vs decision ---"
    sed 's/^/  /' "$WORK/paramdiff.txt" | head -20
    assert 0 "every '- assumes' line is byte-identical to its source (R69 revision 11 line 1885 for web-extra-surface, docs/port/PARAMETERS.md for the rest)"
  fi
  assert "$(eq "$(wc -l < "$WORK/decision-lines.txt" | tr -d ' ')" "6")" \
    "the decision records exactly six assumed parameters: the four owner-fixed ones plus the two researched values the design rests on"
  assert "$(eq "$("$GREP" -c '^- owns ' "$DEC" || true)" "0")" \
    "no '- owns' line: the prompt's Couplings block carries an empty '- owns:' and the registry names no R76-owned row, so inventing one would be a registry edit"
  assert "$(eq "$("$GREP" -c '^CONFLICT:' "$DEC" || true)" "0")" \
    "no CONFLICT: line, which matches the decision's own statement that no consumed parameter has to change"
  # A bare value is what the validator reads; a backticked or annotated one fails publication.
  assert "$(eq "$(countF '- assumes rust-edition = 2024' "$DEC")" "1")" \
    "the rust-edition line carries its value bare, with no backticks, citation or commentary after the '= '"
  assert "$(eq "$(countF '- assumes target-os-matrix = ubuntu-latest, macos-latest' "$DEC")" "1")" \
    "and so does target-os-matrix"
fi
echo

# ---------------------------------------------------------------------------
echo "--- C. the licence gate: recorded with the exact string, and no residue elsewhere ---"
assert "$(eq "$(countF 'inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is' "$DEC")" "1")" \
  "gate 1 is recorded with the required 'inapplicable — owner ruling 2026-09-12 (Q7.B)' string rather than deleted"
assert "$(eq "$(countF 'not evaluated for any dependency or tool' "$DEC")" "1")" \
  "and the string is completed by 'not evaluated for any dependency or tool', so the row states the ruling in full"
# Mechanical enumeration: every case-insensitive hit for 'licen' must be one of
# the four accounted-for locations. Anything else is surviving gate-1 reasoning.
LICEN=$("$GREP" -c -i 'licen' "$DEC" || true)
echo "lines containing 'licen' (case-insensitive) = ${LICEN}; enumerated:"
"$GREP" -n -i 'licen' "$DEC" | cut -c1-96 | sed 's/^/  /'
assert "$(eq "$LICEN" "4")" \
  "exactly four lines mention a licence: the two that carry the inapplicable string and its source, the bare '- assumes license' registry line, and the prose that says the parameter is recorded and evaluated against nothing — no candidate is selected or excluded on a licence ground anywhere"
for term in MulanPSL copyleft AGPL "patent grant" "licence-compatible" "license-compatible"; do
  assert "$(eq "$(countF "$term" "$DEC")" "0")" \
    "the decision contains no '${term}' reasoning, which the owner ruling struck"
done
echo

# ---------------------------------------------------------------------------
echo "--- D. no personal address anywhere in this run's review directory ---"
HITS=$("$GREP" -rlE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$REVIEW" 2>/dev/null | tr '\n' ' ' || true)
echo "files containing an email-shaped token: ${HITS:-(none)}"
assert "$(eq "${HITS:-}" "")" \
  "no file under review/ contains an email-shaped token: the scripts identify themselves with the repository URL instead"
echo

# ---------------------------------------------------------------------------
echo "--- E. the engine record matches the artifacts it names ---"
validate() { # validate <raw file> -> prints errors=N
  python3 - "$ROOT" "$1" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + "/scripts")
from research_validation import validate_answer_text
errs = validate_answer_text(open(sys.argv[2], encoding="utf-8").read(), "crate")
print("errors=%d" % len(errs))
for e in errs:
    print("  " + e)
PY
}
while IFS='|' read -r name file want; do
  [ -n "$name" ] || continue
  if [ ! -f "$file" ]; then
    skip "E: raw/${name}.md is absent from this extraction, so its hash was not compared"
    continue
  fi
  SHA=$(shasum -a 256 "$file" | cut -d' ' -f1)
  echo "sha256(raw/${name}.md) = ${SHA}"
  assert "$(eq "$SHA" "$want")" \
    "raw/${name}.md hashes to the value the decision's ## Engines section cites"
  assert "$(if [ "$(countF "$SHA" "$DEC")" -ge 1 ]; then echo 1; else echo 0; fi)" \
    "and that hash appears in the decision, so the citation is checkable without leaving the document"
  if [ -f "$ROOT/scripts/research_validation.py" ]; then
    validate "$file" > "$WORK/shape-${name}.txt"
    sed 's/^/  /' "$WORK/shape-${name}.txt"
    assert "$(eq "$("$GREP" -c '^errors=0$' "$WORK/shape-${name}.txt" || true)" "1")" \
      "validate_answer_text(raw/${name}.md, 'crate') reports no shape error: all fifteen H3 fields, in order, each with a body"
  else
    skip "E: scripts/research_validation.py is not reachable, so raw/${name}.md's shape was not re-validated"
  fi
done <<EOF
muse|$MUSE|31be2e15e942401a98031416eef2d7ab2043ddae1a343016c929b87ba88c67c5
opus|$RAW|c2792a6957df5b84fcb6438f2f14312fcae8bbd801055e07f1235e63333a5cf4
EOF
# shellcheck disable=SC2016  # backticks are literal Markdown in the decision text
assert "$(eq "$(countF 'required engines are **`muse, opus`**' "$DEC")" "1")" \
  "the decision states the required engine set, muse and opus, in so many words"
assert "$(if [ "$(countF 'engine_overrides.R76 = ["muse","opus"]' "$DEC")" -ge 1 ] && [ "$(countF 'Q9.B' "$DEC")" -ge 1 ] && [ "$(countF 'Q5.A' "$DEC")" -ge 1 ]; then echo 1; else echo 0; fi)" \
  "and names its authority: the policy's engine_overrides entry, the Q5.A migration and the Q9.B ruling"
assert "$(eq "$(countF 'synthesized from a single engine' "$DEC")" "0")" \
  "and it no longer claims to be synthesized from a single engine"
echo

# ---------------------------------------------------------------------------
echo "--- F. every figure the decision quotes from a sibling log is in that log ---"
# log | token as the log prints it | token as the decision prints it | what it is
while IFS='|' read -r log raw shown what; do
  [ -n "$log" ] || continue
  if [ ! -f "$HERE/$log" ]; then
    skip "F: $log is absent, so ${what} was not cross-checked"
    continue
  fi
  inlog=$(countF "$raw" "$HERE/$log")
  indec=$(countF "$shown" "$DEC")
  if [ "$inlog" != "0" ] && [ "$indec" != "0" ]; then ok=1; else ok=0; fi
  assert "$ok" "${what}: ${log} prints it as '${raw}' and the decision quotes it as '${shown}'"
done <<'FIGURES'
probe-checks.log|= +166464 bytes|+166,464 B|the binary-size cost of the dependency
probe-checks.log|arm=without: 502264 bytes|502,264 → 668,728 bytes|the stripped size without the dependency
probe-checks.log|arm=with: 668728 bytes|502,264 → 668,728 bytes|the stripped size with the dependency
probe-checks.log|handler_hits=0|handler_hits=0|the preflight short-circuit, measured from the handler's side
probe-checks.log|access-control-max-age=600|access-control-max-age: 600|the max-age default imported from py and compiled in this run
probe-checks.log|resolved packages: with the tower-http line 57, without it 55|**57** packages against **55**|the dependency-tree delta
probe-checks.log|resolved dependency tree = 1.85 (hyper-util), under the committed lockfile|**1.85 (`hyper-util`|the maximum declared rust-version in the locked tree
registry-figures.log|2026-08-31T14:49:25.697237Z|2026-08-31T14:49:25.697237Z|tower-http 0.7.1's publication timestamp
registry-figures.log|2026-06-15T14:01:18.432430Z|2026-06-15T14:01:18.432430Z|tower-http 0.7.0's publication timestamp
registry-figures.log|(90-day) = 155482963|155,482,963|the 90-day download figure
registry-figures.log|(all-time)      = 479378847|479,378,847|the all-time download figure
registry-figures.log|meta.total = 36|**36**|the size of the enumerated cors category
registry-figures.log|q=cors meta.total = 1476|**1,476**|the q=cors name-match count
registry-figures.log|stargazers_count = 918|**918** stars|tower-http's star count
registry-figures.log|pushed_at = 2026-09-26T12:33:00Z|2026-09-26T12:33:00Z|tower-http's pushed_at
registry-figures.log|the field the prompt requires) = 32|**32** open issues|tower-http's open issues by search total_count
registry-figures.log|open_issues_count = 40|reads **40**|the open_issues_count deliberately not used
registry-figures.log|Cargo.toml@765bbf478827f421a93ea2634997b2b4f55c87f4:168:tower-http = { version = "=0.7.1"|Cargo.toml@765bbf478827f421a93ea2634997b2b4f55c87f4:168|the rust-lang/crates.io pin, by commit and line
muse-adjudication.log|tower-http reverse_dependencies meta.total = 3532|**3,532**|tower-http's reverse-dependency count
muse-adjudication.log|actix-cors reverse_dependencies meta.total = 214|214 reverse dependencies|actix-cors's reverse-dependency count
muse-adjudication.log|(90-day) = 2914000; crate.downloads (all-time) = 21295772|**2,914,000**|actix-cors's 90-day downloads
muse-adjudication.log|(90-day) = 2914000; crate.downloads (all-time) = 21295772|**21,295,772**|actix-cors's all-time downloads
muse-adjudication.log|maximum declared rust-version = 1.88.0 (time-macros)|1.88.0 (`time-macros`)|actix-cors's tree MSRV
muse-adjudication.log|actix/actix-extras: stargazers_count = 890|**890**|actix-extras's star count
muse-adjudication.log|loco-rs/loco: stargazers_count = 9267|9,267 stars|loco's star count
muse-adjudication.log|tokio-rs/console: stargazers_count = 4604|4,604 stars|console's star count
muse-adjudication.log|rubric_window answered=2 unanswered=8 closed_unanswered=2|**two** carry a maintainer comment|the rubric-window responsiveness figures
muse-adjudication.log|median_answered_h=2.30|**2.30 h**|the median over the answered subset
muse-adjudication.log|muse_window answered=0 unanswered=4|0 of 4|the Muse-window responsiveness figures
muse-adjudication.log|pushed_at = 2023-11-20T00:42:55Z|2023-11-20T00:42:55Z|rocket_cors's last push
muse-adjudication.log|files differing under src/cors between 0.7.0 and 0.7.1 = 0|byte-identical in the published 0.7.0 and 0.7.1|the 0.7.0-to-0.7.1 cors source comparison
FIGURES
for log in registry-figures.log probe-checks.log muse-adjudication.log; do
  if [ ! -f "$HERE/$log" ]; then
    skip "F: $log is absent, so its own verdict was not checked"
    continue
  fi
  assert "$(eq "$(tail -1 "$HERE/$log")" "RESULT: PASS")" \
    "${log} ends in RESULT: PASS, so the decision is citing a passing run"
  assert "$(eq "$("$GREP" -c 'ASSERT FAIL' "$HERE/$log" || true)" "0")" \
    "${log} records no ASSERT FAIL line"
done
echo

# ---------------------------------------------------------------------------
echo "--- G. every path:line citation in the decision resolves ---"
# A citation is `path:line` or `path:first-last`. Each one is either
#   local    — a file under the repository root, this run, review/ or evidence/,
#              which must exist and have at least that many lines;
#   py       — a py-launch-blueprint path, checked at pin b08bccfb in PY_REPO;
#   external — a path inside a published artifact another script reads; it must
#              be on the explicit list below, so a mistyped local path cannot
#              pass silently as "external".
python3 - "$DEC" "$ROOT" "$RUN" "$REVIEW" "$HERE" "$PY_REPO" "$PY_PIN" > "$WORK/cites.txt" <<'PY'
import os, re, subprocess, sys
dec, root, run, review, here, py_repo, py_pin = sys.argv[1:8]
text = open(dec, encoding="utf-8").read()
pat = re.compile(r"`?([A-Za-z0-9_./-]+\.(?:md|sh|json|rs|toml|yml|yaml|py|log|lock)):(\d+)(?:(?:[-–]|`–`)(\d+))?")
EXTERNAL = {
    # read by registry-figures.sh from the published tower-http .crate files
    "tower-http-0.7.1/Cargo.toml", "tower-http-0.7.1/src/lib.rs", "tower-http-0.7.1/src/cors/mod.rs",
    "src/services/fs/serve_dir/tests.rs", "mod.rs",
    # read by rest-conformance-r2.sh from the locked axum 0.8.9 source
    "axum-0.8.9/src/routing/method_routing.rs", "axum-0.8.9/src/routing/route.rs",
    # read by muse-adjudication.sh from the published actix-cors .crate
    "actix-cors-0.7.2/src/lib.rs",
    # read by registry-figures.sh section I from the adopters' default branches;
    # a bare Cargo.toml is tonic-web's (line 31) or revision 2's superseded
    # crates.io citation (line 170), quoted as history
    "console-subscriber/Cargo.toml", "Cargo.toml", "examples/cors/Cargo.toml",
}
PY_PREFIXES = ("src/py_launch_blueprint/", "docs/adr/")
bad = local = py = ext = 0
seen = set()
for m in pat.finditer(text):
    path, a, b = m.group(1), int(m.group(2)), int(m.group(3) or m.group(2))
    if (path, a, b) in seen:
        continue
    seen.add((path, a, b))
    hit = next((os.path.join(d, path) for d in (root, run, review, here)
                if os.path.isfile(os.path.join(d, path))), None)
    if hit:
        n = sum(1 for _ in open(hit, encoding="utf-8", errors="replace"))
        ok = b <= n
        local += 1
        print("%s local    %s:%d-%d (file has %d lines)" % ("ok  " if ok else "FAIL", path, a, b, n))
    elif path.startswith(PY_PREFIXES):
        if not os.path.isdir(py_repo):
            print("skip py       %s:%d-%d (no clone at %s)" % (path, a, b, py_repo))
            continue
        r = subprocess.run(["git", "-C", py_repo, "show", "%s:%s" % (py_pin, path)],
                           capture_output=True, text=True)
        n = len(r.stdout.splitlines()) if r.returncode == 0 else -1
        ok = 0 < b <= n
        py += 1
        print("%s py       %s:%d-%d at %s (file has %d lines)" % ("ok  " if ok else "FAIL", path, a, b, py_pin, n))
    else:
        ok = path in EXTERNAL
        ext += 1
        print("%s external %s:%d-%d" % ("ok  " if ok else "FAIL", path, a, b))
    if not ok:
        bad += 1
print("SUMMARY local=%d py=%d external=%d unresolved=%d" % (local, py, ext, bad))
PY
sed 's/^/  /' "$WORK/cites.txt"
SUM=$("$GREP" '^SUMMARY ' "$WORK/cites.txt")
assert "$(if printf '%s' "$SUM" | "$GREP" -q 'unresolved=0$'; then echo 1; else echo 0; fi)" \
  "every path:line citation resolves: each local file exists with at least the cited line, each py-launch-blueprint path exists at pin b08bccfb, and each other path is a named published-artifact path another script reads"
LOCALN=$(printf '%s' "$SUM" | "$GREP" -o 'local=[0-9]*' | cut -d= -f2)
assert "$(if [ "${LOCALN:-0}" -gt 0 ]; then echo 1; else echo 0; fi)" \
  "and the local set is non-empty, so the check exercised the repository and not only the allowlist"
R69DEC="$ROOT/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
if [ -f "$R69DEC" ]; then
  assert "$(if sed -n '1885p' "$R69DEC" | "$GREP" -q '^- owns web-extra-surface = '; then echo 1; else echo 0; fi)" \
    "the prose citation of R69 revision 11's '- owns web-extra-surface' line at line 1885 resolves to that line"
else
  skip "G: R69 revision 11's decision is not reachable, so its line-1885 citation was not resolved"
fi
echo

# ---------------------------------------------------------------------------
echo "=== RESULT ==="
echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
if [ "$failn" -gt 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"
