"""Print the five `- assumes` lines R58 must carry, built from the live registry.

The set is the four fixed parameters plus the one parameter R58's binding prompt
declares on its `- consumes:` line (`R69: web-extra-surface`). The packaging
validator reads everything after `= ` as the value and compares it byte-for-byte
with the matching row of docs/port/PARAMETERS.md, so the value is emitted bare.
"""

import sys

ORDER = ["msrv-policy", "rust-edition", "target-os-matrix", "license", "web-extra-surface"]

vals = {}
with open(sys.argv[1], encoding="utf-8") as fh:
    for line in fh:
        if not line.startswith("|"):
            continue
        cells = line.split("|")
        if len(cells) < 6:
            continue
        name = cells[1].strip()
        if name in ORDER:
            vals[name] = cells[4].strip()

missing = [k for k in ORDER if k not in vals]
if missing:
    sys.exit(f"parameter rows not found in the registry: {missing}")
for k in ORDER:
    print(f"- assumes {k} = {vals[k]}")
