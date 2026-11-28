#!/usr/bin/env python3
"""Verify docs/port/FINAL-PARITY-AUDIT.md accounts for every F### row, R## item,
post-b08bccf py-launch-blueprint v4.2.0 delta item, Blaze status, and human setup checklist.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
COMMONALITY_PATH = ROOT / "docs/port/COMMONALITY.md"
RESEARCH_INDEX_PATH = ROOT / "research/CLAUDE.md"
AUDIT_PATH = ROOT / "docs/port/FINAL-PARITY-AUDIT.md"

VALID_STATUSES = {
    "IMPLEMENTED",
    "OMITTED (non-analogous)",
    "DEFERRED",
}

REQUIRED_DELTA_MARKERS = [
    "difftree-action",
    "template-press",
    "new-rust-project",
    "OTel",
    "[parallel]",
    "release-please",
    "ShellCheck",
    "CODEOWNERS",
    "publish-container.yml",
    "audit-triage.yml",
    "OSS Scanner",
]

REQUIRED_SECTIONS = [
    "## Executive Summary",
    "## Full 360-Row `COMMONALITY.md` Parity Ledger",
    "## Post-`b08bccf` `py-launch-blueprint` `v4.2.0` Delta Audit",
    "## Research Program Coverage (`R01`–`R86`)",
    "## Blaze Local Accelerator Status",
    "## Final Human GitHub Setup Checklist",
]


def parse_commonality(path: pathlib.Path) -> dict[str, dict[str, str]]:
    rows: dict[str, dict[str, str]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("| F"):
            continue
        parts = [cell.strip() for cell in line.strip("|").split("|")]
        if len(parts) < 7:
            continue
        fid, feature, area, origin, verdict, item, notes = parts[:7]
        if fid in rows:
            raise ValueError(f"duplicate feature ID in COMMONALITY.md: {fid}")
        rows[fid] = {
            "feature": feature,
            "area": area,
            "origin": origin,
            "verdict": verdict,
            "item": item,
            "notes": notes,
        }
    return rows


def parse_research_items(path: pathlib.Path) -> list[str]:
    items: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\|\s*(R\d{2})\s*\|", line)
        if m:
            items.append(m.group(1))
    return items


def parse_audit_feature_rows(text: str) -> tuple[dict[str, dict[str, str]], list[str]]:
    rows: dict[str, dict[str, str]] = {}
    duplicates: list[str] = []
    for line in text.splitlines():
        if not line.startswith("| F"):
            continue
        parts = [cell.strip() for cell in line.strip("|").split("|")]
        if len(parts) < 6:
            continue
        fid = parts[0]
        if fid in rows:
            duplicates.append(fid)
            continue
        rows[fid] = {
            "area": parts[1],
            "verdict": parts[2],
            "item": parts[3],
            "status": parts[4],
            "evidence": parts[5],
        }
    return rows, duplicates


def main() -> int:
    errors: list[str] = []

    if not COMMONALITY_PATH.is_file():
        print(f"FAIL: missing {COMMONALITY_PATH}", file=sys.stderr)
        return 1
    if not RESEARCH_INDEX_PATH.is_file():
        print(f"FAIL: missing {RESEARCH_INDEX_PATH}", file=sys.stderr)
        return 1
    if not AUDIT_PATH.is_file():
        print(f"FAIL: missing {AUDIT_PATH}", file=sys.stderr)
        return 1

    commonality = parse_commonality(COMMONALITY_PATH)
    research_items = parse_research_items(RESEARCH_INDEX_PATH)
    audit_text = AUDIT_PATH.read_text(encoding="utf-8")
    audit_rows, duplicates = parse_audit_feature_rows(audit_text)

    if len(commonality) != 360:
        errors.append(f"expected 360 F### rows in COMMONALITY.md, found {len(commonality)}")
    if len(research_items) != 85:
        errors.append(f"expected 85 R## rows in research/CLAUDE.md, found {len(research_items)}")

    if duplicates:
        errors.append(f"duplicate F### rows in FINAL-PARITY-AUDIT.md: {', '.join(duplicates)}")

    expected_ids = set(commonality.keys())
    actual_ids = set(audit_rows.keys())
    missing = sorted(expected_ids - actual_ids)
    extra = sorted(actual_ids - expected_ids)
    if missing:
        errors.append(
            f"missing {len(missing)} F### rows from FINAL-PARITY-AUDIT.md: {', '.join(missing[:20])}"
        )
    if extra:
        errors.append(
            f"unexpected {len(extra)} F### rows in FINAL-PARITY-AUDIT.md: {', '.join(extra[:20])}"
        )

    omit_count = 0
    implemented_count = 0
    for fid in sorted(expected_ids & actual_ids):
        src = commonality[fid]
        aud = audit_rows[fid]
        if aud["area"] != src["area"]:
            errors.append(f"{fid}: area mismatch (audit={aud['area']!r}, source={src['area']!r})")
        if aud["item"] != src["item"]:
            errors.append(f"{fid}: item mismatch (audit={aud['item']!r}, source={src['item']!r})")
        if aud["status"] not in VALID_STATUSES:
            errors.append(f"{fid}: invalid status {aud['status']!r}")
        if src["verdict"] == "OMIT":
            if aud["status"] != "OMITTED (non-analogous)":
                errors.append(
                    f"{fid}: OMIT row must have status 'OMITTED (non-analogous)', got {aud['status']!r}"
                )
            omit_count += 1
        else:
            if aud["status"] != "IMPLEMENTED":
                errors.append(
                    f"{fid}: non-OMIT row ({src['verdict']}) must be 'IMPLEMENTED', got {aud['status']!r}"
                )
            implemented_count += 1
        if not aud["evidence"] or aud["evidence"] in {"-", "—", "TBD", "TODO"}:
            errors.append(f"{fid}: missing concrete implementation evidence")

    if omit_count != 10:
        errors.append(f"expected 10 OMITTED rows, counted {omit_count}")
    if implemented_count != 350:
        errors.append(f"expected 350 IMPLEMENTED rows, counted {implemented_count}")

    for rid in research_items:
        if not re.search(rf"\b{re.escape(rid)}\b", audit_text):
            errors.append(f"research item {rid} not referenced in FINAL-PARITY-AUDIT.md")

    for section in REQUIRED_SECTIONS:
        if section not in audit_text:
            errors.append(f"missing required section heading: {section}")

    for marker in REQUIRED_DELTA_MARKERS:
        if marker not in audit_text:
            errors.append(f"missing required post-b08bccf delta coverage marker: {marker}")

    if "docs/PROJECT_SETUP.md" not in audit_text and "PROJECT_SETUP.md" not in audit_text:
        errors.append("FINAL-PARITY-AUDIT.md must reference PROJECT_SETUP.md")

    if errors:
        print(f"FAIL: parity audit check failed with {len(errors)} error(s):", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(
        "OK: FINAL-PARITY-AUDIT.md verified "
        f"({len(audit_rows)}/360 F### rows: {implemented_count} IMPLEMENTED, "
        f"{omit_count} OMITTED; {len(research_items)}/85 R## items; "
        f"{len(REQUIRED_DELTA_MARKERS)}/{len(REQUIRED_DELTA_MARKERS)} post-b08bccf delta items)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
