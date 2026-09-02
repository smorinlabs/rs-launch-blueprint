#!/usr/bin/env python3
"""Derive docs/port/COVERAGE.md and the per-repo inventories from the area files and the ledger.

usage: derive-port-docs.py coverage    [--root DIR] [--files LIST] [--check]
       derive-port-docs.py inventories [--root DIR] [--check]
COVERAGE.md keeps its hand-written '## Exclusion rules' bullets (- `glob` — reason); the table is regenerated.
Exit 1 on UNCOVERED files or, with --check, on drift between committed and regenerated output.
"""
import argparse, fnmatch, pathlib, re, subprocess, sys, tempfile

REPOS = {"py": pathlib.Path.home() / "c/py-launch-blueprint", "ts": pathlib.Path.home() / "c/ts-launch-blueprint"}
CITE = re.compile(r"`([^`:]+):(\d+)`")
ROW = re.compile(r"^\|\s*(F\d{3})\s*\|(.*)\|\s*$")

def rows(table_file):
    """Yield (cells) for data rows of the single pipe table in table_file, header first."""
    out = []
    for line in table_file.read_text().splitlines():
        if line.startswith("|") and not line.startswith("|---"):
            out.append([c.strip() for c in line.strip().strip("|").split("|")])
    return out

def list_files(files_arg):
    if files_arg:
        return [l.strip() for l in pathlib.Path(files_arg).read_text().splitlines() if l.strip()]
    acc = []
    for tag, repo in REPOS.items():
        ls = subprocess.run(["git", "-C", str(repo), "ls-files"], check=True, capture_output=True, text=True).stdout
        acc += [f"{tag}:{p}" for p in ls.splitlines() if p]
    return acc

def coverage(root, files_arg, check):
    areas = sorted((root / "docs/port/areas").glob("*.md"))
    feat = {}      # "py:path" -> set(F###)
    read_note = {} # "py:path" -> reason for a read-but-featureless file
    for a in areas:
        if a.name == "SURVEY-PROMPT.md":
            continue
        cells = rows(a)
        hdr = cells[0]
        if hdr[0] != "id":
            sys.exit(f"{a}: area table has no id column (run Phase 2 first)")
        ipy, its = hdr.index("py"), hdr.index("ts")
        for r in cells[1:]:
            for tag, i in (("py", ipy), ("ts", its)):
                for path, _ in CITE.findall(r[i]):
                    feat.setdefault(f"{tag}:{path}", set()).add(r[0])
        for line in a.read_text().splitlines():
            m = re.match(r"^- (py|ts): `([^`]+)`(?: — no feature: (.*))?$", line)
            if m and m.group(3):
                read_note[f"{m.group(1)}:{m.group(2)}"] = m.group(3).strip()
    cov = root / "docs/port/COVERAGE.md"
    text = cov.read_text() if cov.exists() else "# Coverage manifest\n\n## Exclusion rules\n"
    rules = re.findall(r"^- `([^`]+)` — (.+)$", text.split("## Exclusion rules", 1)[1], re.M) if "## Exclusion rules" in text else []
    head = text.split("| repo |")[0].rstrip() + "\n\n"
    lines = ["| repo | path | features |", "|---|---|---|"]
    uncovered = []
    for f in list_files(files_arg):
        tag, path = f.split(":", 1)
        if f in feat:
            val = " ".join(sorted(feat[f]))
        elif f in read_note:
            val = f"EXCLUDED: {read_note[f]}"
        else:
            reason = next((why for glob, why in rules if fnmatch.fnmatch(path, glob) or fnmatch.fnmatch(pathlib.Path(path).name, glob)), None)
            if reason is None:
                uncovered.append(f); val = "UNCOVERED"
            else:
                val = f"EXCLUDED: {reason}"
        lines.append(f"| {tag} | {path} | {val} |")
    out = head + "\n".join(lines) + "\n"
    return write_or_check(cov, out, check, uncovered)

def inventories(root, check):
    led = rows(root / "docs/port/COMMONALITY.md")
    hdr = led[0]; io, iv = hdr.index("Origin"), hdr.index("Verdict")
    rc = 0
    for tag, name, origins in (("py", "PY_INVENTORY.md", {"same", "different", "py-only"}), ("ts", "TS_INVENTORY.md", {"same", "different", "ts-only"})):
        lines = [f"# {tag}-launch-blueprint inventory (derived from COMMONALITY.md — do not edit)", "",
                 "| ID | Feature | Area | Verdict | Item |", "|---|---|---|---|---|"]
        for r in led[1:]:
            if r[io] in origins:
                lines.append(f"| {r[0]} | {r[1]} | {r[2]} | {r[iv]} | {r[hdr.index('Item')]} |")
        rc |= write_or_check(root / "docs/port" / name, "\n".join(lines) + "\n", check, [])
    return rc

def write_or_check(path, out, check, uncovered):
    for u in uncovered:
        print(f"UNCOVERED: {u}")
    if check:
        if path.exists() and path.read_text() == out and not uncovered:
            print(f"OK: {path} is current"); return 0
        print(f"DRIFT: {path} differs from regenerated output" if path.exists() and path.read_text() != out else f"OK: {path} content current")
        return 1 if (uncovered or path.read_text() != out) else 0
    path.write_text(out)
    print(f"wrote {path} ({out.count(chr(10))} lines)")
    return 1 if uncovered else 0

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["coverage", "inventories"])
    ap.add_argument("--root", default=str(pathlib.Path(__file__).resolve().parent.parent))
    ap.add_argument("--files"); ap.add_argument("--check", action="store_true")
    a = ap.parse_args(); root = pathlib.Path(a.root)
    sys.exit(coverage(root, a.files, a.check) if a.cmd == "coverage" else inventories(root, a.check))
