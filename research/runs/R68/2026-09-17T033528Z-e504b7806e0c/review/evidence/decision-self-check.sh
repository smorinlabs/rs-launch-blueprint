#!/usr/bin/env bash
# R68 empirical check, part 3 of 3: assert that this decision's own record is
# internally correct — that every `- assumes` line in DECISION.md is
# byte-identical to the row it names in docs/port/PARAMETERS.md, that the
# `## Parameters` grammar matches the prompt's `## Couplings` block, and that
# every ledger and owner-review location this decision cites exists and says
# what the decision says it says.
#
# Reads only files that are present in a clean `git archive HEAD` extraction.
# It reads no `.git` and touches no network.
#
# Every line is an ASSERT: a failure exits 1.

set -euo pipefail

GREP=/usr/bin/grep
HERE=$(cd "$(dirname "$0")" && pwd)
REVIEW=$(cd "${HERE}/.." && pwd)
RUN=$(cd "${REVIEW}/.." && pwd)
REPO=$(cd "${RUN}/../../../.." && pwd)

DECISION="${REVIEW}/DECISION.md"
PROMPT="${RUN}/inputs/prompt.md"
REGISTRY="${REPO}/docs/port/PARAMETERS.md"
LEDGER="${REPO}/docs/port/COMMONALITY.md"
OWNER="${REPO}/docs/port/OWNER-REVIEW.md"
REFERENCE="${REPO}/docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md"

echo "=== R68 decision self-check ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
for f in "$DECISION" "$PROMPT" "$REGISTRY" "$LEDGER" "$OWNER" "$REFERENCE"; do
  if [ ! -f "$f" ]; then
    echo "SKIP: ${f} is absent from this extraction; cannot run" >&2
    exit 1
  fi
done
echo "decision: $(basename "$DECISION") ($(wc -c <"$DECISION" | tr -d ' ') bytes)"
echo

fail=0
assert() {
  if [ "$1" = "1" ]; then
    echo "ASSERT ok   $2"
  else
    echo "ASSERT FAIL $2"
    fail=1
  fi
}
has() { if [ "$1" -gt 0 ]; then echo 1; else echo 0; fi; }

# --- 1. the H2 set, in order ------------------------------------------------
echo "--- 1. heading set ---"
"$GREP" -n '^## ' "$DECISION"
HEADS=$("$GREP" '^## ' "$DECISION" | tr '\n' '|')
assert "$(if [ "$HEADS" = "## Decision|## Parameters|## Empirical check|## Engines|" ]; then echo 1; else echo 0; fi)" \
  "the H2 set is exactly Decision, Parameters, Empirical check, Engines, in that order"
N=$("$GREP" -c '^### Principles and implementation$' "$DECISION" || true)
assert "$(has "$N")" "the required H3 'Principles and implementation' is present"
N=$("$GREP" -c '^## Supersedes' "$DECISION" || true)
assert "$(if [ "$N" -eq 0 ]; then echo 1; else echo 0; fi)" \
  "no '## Supersedes' section is present, this being revision 1"
N=$("$GREP" -c '^re-verify: ' "$DECISION" || true)
assert "$(has "$N")" "a 're-verify:' line is present"
echo

# --- 2. the `- owns` / `- consumes` grammar against the prompt ---------------
echo "--- 2. Parameters grammar against the prompt's ## Couplings block ---"
OWNS_LINE=$("$GREP" -n '^- owns:' "$PROMPT" | head -1)
echo "prompt: ${OWNS_LINE}"
OWNS_VALUE=$("$GREP" '^- owns:' "$PROMPT" | head -1 | /usr/bin/sed 's/^- owns://' | tr -d ' \t')
echo "prompt '- owns:' payload after trimming whitespace = '${OWNS_VALUE}' (empty means this item owns nothing)"
DECISION_OWNS=$("$GREP" -c '^- owns ' "$DECISION" || true)
echo "/usr/bin/grep -c '^- owns ' DECISION.md = ${DECISION_OWNS}"
assert "$(if [ -z "$OWNS_VALUE" ] && [ "$DECISION_OWNS" -eq 0 ]; then echo 1; else echo 0; fi)" \
  "the prompt's '- owns:' line is empty and DECISION.md writes no '- owns' line"
REG_OWNS=$("$GREP" -c '| researched | R68 |' "$REGISTRY" || true)
echo "/usr/bin/grep -c '| researched | R68 |' docs/port/PARAMETERS.md = ${REG_OWNS}"
assert "$(if [ "$REG_OWNS" -eq 0 ]; then echo 1; else echo 0; fi)" \
  "the registry records no parameter owned by R68, so writing an '- owns' line would invent a registry row"
"$GREP" -n '^- consumes:' "$PROMPT" | head -1
N=$("$GREP" -c '^- consumes: R49: build-tool-output-shape$' "$PROMPT" || true)
assert "$(has "$N")" "the prompt consumes exactly R49's build-tool-output-shape"
echo

# --- 3. every `- assumes` line is byte-identical to the registry row ---------
echo "--- 3. '- assumes' lines against docs/port/PARAMETERS.md ---"
if python3 - "$DECISION" "$REGISTRY" <<'PY'
import sys
decision_path, registry_path = sys.argv[1], sys.argv[2]

registry = {}
for line in open(registry_path, encoding="utf-8"):
    if line.startswith("| "):
        parts = line.rstrip("\n").split("|")
        if len(parts) >= 7:
            registry[parts[1].strip()] = parts[4].strip()

assumes = []
for line in open(decision_path, encoding="utf-8"):
    if line.startswith("- assumes "):
        body = line.rstrip("\n")[len("- assumes "):]
        name, _, value = body.partition(" = ")
        assumes.append((name, value))

required = ["build-tool-output-shape", "msrv-policy", "rust-edition",
            "target-os-matrix", "license"]
names = [n for n, _ in assumes]
print(f"assumes lines found: {len(assumes)} -> {names}")

bad = 0
for name in required:
    if name not in names:
        print(f"ASSERT FAIL missing '- assumes {name}' line")
        bad = 1
for name, value in assumes:
    if name not in registry:
        print(f"ASSERT FAIL '{name}' is not a row in the registry")
        bad = 1
        continue
    want = registry[name]
    if value == want:
        print(f"ASSERT ok   '- assumes {name}' is byte-identical to the registry "
              f"({len(value)} chars)")
    else:
        print(f"ASSERT FAIL '- assumes {name}' differs from the registry")
        print(f"            decision: {value[:120]!r}...")
        print(f"            registry: {want[:120]!r}...")
        bad = 1
    if "`" in value:
        print(f"ASSERT FAIL '- assumes {name}' contains a backtick; the validator "
              f"reads everything after '= ' as the value")
        bad = 1
sys.exit(bad)
PY
then params_ok=1; else params_ok=0; fi
assert "$params_ok" "every '- assumes' line matches its registry row byte-for-byte, with no backticks"
echo

# --- 4. the ledger and owner-review locations this decision cites ------------
echo "--- 4. cited ledger and owner-review locations ---"
N=$(/usr/bin/sed -n '218p' "$LEDGER" | "$GREP" -c '^| F214 | distributable artifact types |' || true)
/usr/bin/sed -n '218p' "$LEDGER" | cut -c1-120
assert "$(has "$N")" "docs/port/COMMONALITY.md:218 is the F214 row this decision settles"
N=$(/usr/bin/sed -n '224p' "$LEDGER" | "$GREP" -c '^| F220 | documented end-user install method |' || true)
/usr/bin/sed -n '224p' "$LEDGER" | cut -c1-120
assert "$(has "$N")" "docs/port/COMMONALITY.md:224 is the F220 row whose value this decision derives"
N=$(/usr/bin/sed -n '78p' "$LEDGER" | "$GREP" -c 'create-github-app-token' || true)
/usr/bin/sed -n '78p' "$LEDGER" | cut -c1-160
assert "$(has "$N")" \
  "docs/port/COMMONALITY.md:78 is the F072 row naming the App-token source the release-please to dist hand-off depends on"
N=$("$GREP" -c '^### 2026-09-16 — Release build profile ownership: R68 (W0-R69p)$' "$OWNER" || true)
assert "$(has "$N")" "the owner-review section that moved the profile subject onto R68 exists verbatim"
N=$("$GREP" -c 'no licence check for anything the template uses' "$OWNER" || true)
assert "$(has "$N")" "the 2026-09-12 Q7.B licence ruling that answers fitness gate 1 'inapplicable' exists"
echo

# --- 5. the owner reference rows this decision reconciles --------------------
echo "--- 5. the owner reference architecture's profile row, quoted verbatim ---"
"$GREP" -n -B1 -A2 '^\[profile.release\]$' "$REFERENCE"
N=$("$GREP" -c '^lto = "thin"$' "$REFERENCE" || true)
M=$("$GREP" -c '^codegen-units = 1$' "$REFERENCE" || true)
echo "/usr/bin/grep -c '^lto = \"thin\"\$' owner reference = ${N}"
echo "/usr/bin/grep -c '^codegen-units = 1\$' owner reference = ${M}"
assert "$(if [ "$N" -gt 0 ] && [ "$M" -gt 0 ]; then echo 1; else echo 0; fi)" \
  "the owner reference's Reference Cargo.toml section states lto = \"thin\" and codegen-units = 1 — the row this decision agrees with on one key and differs from on the other"
N=$("$GREP" -c 'compiled in my head, not against the toolchain' "$REFERENCE" || true)
assert "$(has "$N")" \
  "the owner reference's own Caveats section records that its material was compiled in the author's head rather than against the toolchain"
N=$("$GREP" -c 'distroless/cc-debian12' "$REFERENCE" || true)
assert "$(has "$N")" "the container rows this decision hands to R51 are in the reference's C15 section"
echo

# --- 6. no personal email anywhere in what this item publishes ---------------
echo "--- 6. privacy ---"
EMAILS=$(mktemp "${TMPDIR:-/tmp}/r68-emails.XXXXXX")
trap 'rm -f "$EMAILS"' EXIT
"$GREP" -r -E -l '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$REVIEW" >"$EMAILS" 2>/dev/null || true
N=$("$GREP" -c . "$EMAILS" || true)
echo "files under review/ containing an email-shaped string = ${N}"
cat "$EMAILS"
assert "$(if [ "$N" -eq 0 ]; then echo 1; else echo 0; fi)" \
  "no email address appears anywhere under review/"
echo

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL — at least one assertion did not hold"
  exit 1
fi
echo "RESULT: PASS — every assertion held"
