#!/usr/bin/env bash
# R69 evidence: the `## Parameters` block must survive the packaging validator,
# which reads everything after "= " as the value and compares it byte-for-byte
# with docs/port/PARAMETERS.md. This re-derives each fixed/consumed value from
# the registry and diffs it against the line in review/DECISION.md.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEC="$HERE/../DECISION.md"
REPO="$(cd "$HERE/../../../../../.." && pwd)"
REG="$REPO/docs/port/PARAMETERS.md"
rc=0
echo "decision: $DEC"
echo "registry: $REG"
[ -f "$REG" ] || { echo "FAIL: registry not found"; exit 1; }

python3 - "$REG" "$DEC" <<'PY'
import sys, pathlib
reg_path, dec_path = sys.argv[1], sys.argv[2]
rows = {}
for ln in pathlib.Path(reg_path).read_text().split("\n"):
    if ln.startswith("| ") and ln.count("|") >= 6:
        c = [x.strip() for x in ln.split("|")]
        if len(c) >= 6 and c[1] not in ("param", "---"):
            rows[c[1]] = c[4]

dec = pathlib.Path(dec_path).read_text().split("\n")
assumes = {}
owns = {}
for ln in dec:
    if ln.startswith("- assumes "):
        k, _, v = ln[len("- assumes "):].partition(" = ")
        assumes[k] = v
    elif ln.startswith("- owns "):
        k, _, v = ln[len("- owns "):].partition(" = ")
        owns[k] = v

rc = 0
expected = ["msrv-policy", "rust-edition", "target-os-matrix", "license",
            "http-transport-injection-seam"]
if sorted(assumes) != sorted(expected):
    print(f"FAIL: assumes keys are {sorted(assumes)}, expected {sorted(expected)}"); rc = 1
else:
    print(f"OK   the five expected '- assumes' lines are present and no others")

for k in expected:
    if k not in assumes:
        print(f"FAIL {k}: missing from the decision"); rc = 1; continue
    if k not in rows:
        print(f"FAIL {k}: missing from the registry"); rc = 1; continue
    if assumes[k] == rows[k]:
        print(f"OK   {k}: byte-identical to the registry ({len(rows[k])} bytes)")
    else:
        print(f"FAIL {k}: differs from the registry")
        print(f"     registry: {rows[k][:120]!r}")
        print(f"     decision: {assumes[k][:120]!r}"); rc = 1

if list(owns) != ["web-extra-surface"]:
    print(f"FAIL: owns keys are {list(owns)}, expected ['web-extra-surface']"); rc = 1
else:
    v = owns["web-extra-surface"]
    print(f"OK   exactly one '- owns' line, for web-extra-surface ({len(v)} bytes)")
    # Format rules the validator enforces on the value itself.
    for bad, why in [("`", "backticks"), ("](", "a markdown link"), ("  ", "a double space")]:
        if bad in v:
            print(f"FAIL owns value contains {why}"); rc = 1
        else:
            print(f"OK   owns value contains no {why}")
    if v != v.strip():
        print("FAIL owns value has leading or trailing whitespace"); rc = 1
    else:
        print("OK   owns value has no leading or trailing whitespace")

# Control: the comparison must be able to fail.
probe = rows["rust-edition"] + "X"
print("OK   control: a deliberately altered value compares unequal"
      if probe != rows["rust-edition"] else "FAIL control: comparison is a no-op")

# The H2 section list the role contract fixes, in order.
h2 = [l for l in dec if l.startswith("## ")]
want = ["## Decision", "## Parameters", "## Empirical check", "## Engines"]
if h2 == want:
    print("OK   H2 sections are exactly " + ", ".join(want))
else:
    print(f"FAIL H2 sections are {h2}, expected {want}"); rc = 1

print(f"parameters-check rc={rc}")
sys.exit(rc)
PY
