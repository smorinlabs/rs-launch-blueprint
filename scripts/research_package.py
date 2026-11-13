#!/usr/bin/env python3
"""Package one completed research run into a reviewable publication manifest.

The tool reads a prepared run directory, copies the evidence it recorded into a
staged tree, and derives the acceptance bundle that the strict validator
demands.  It assembles and hashes a record; it cannot establish that the
research, the audits, or the empirical command actually happened.  Nothing here
contacts a provider, and nothing here writes to the repository: publication
stays a separate, reviewed step through `research_runner.py publication apply`.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import research_runner as runner
import research_validation as validator
from research_cli import Parser, UsageError, add_common_arguments, diagnostic, emit_error, parse_args

VERSION = "0.1.0"
IDENTITY_FIELDS = ("actor", "model", "family")
AUDIT_FIELDS = ("decision-sha256", "actor", "model", "family", "verdict", "unresolved-findings")
AUDIT_FILES = {"empirical": "audit-codex.md", "judgment": "audit-fable.md"}
EMPIRICAL_FIELDS = {"argv", "cwd", "toolchain", "output_log", "exit_code"}
IDENTITIES_FIELDS = {"engine_reports", "evidence_checks", "synthesis", "audits", "empirical"}
STAGED_NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*\.(?:md|log)")
DECLARATION = re.compile(r"^- (owns|assumes)\s+([a-z0-9-]+)\s*=\s*(.+?)\s*$")
AUDIT_FIELD = re.compile(r"^(%s):\s*(.*?)\s*$" % "|".join(AUDIT_FIELDS), re.I)
STATUS_CELL = re.compile(r"\|\s*(?:open|in-progress|resolved)\s*\|(\s*)$")


class PackageError(Exception):
    """A refusal: the run does not yet support a publishable acceptance bundle."""


def require(condition: Any, message: str) -> None:
    if not condition:
        raise PackageError(message)


def under(base: Path, relative: str, label: str) -> Path:
    """Confine a data-supplied relative path; report it as a refusal, not usage."""
    try:
        return runner.under(base, relative)
    except UsageError as exc:
        raise PackageError("%s: %s" % (label, exc)) from exc


def regular_file(path: Path, label: str) -> Path:
    require(path.is_file() and not path.is_symlink(), "missing required %s: %s" % (label, path.name))
    return path


def text_of(path: Path, label: str) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise PackageError("cannot read %s: %s" % (label, exc)) from exc


def identity(value: Any, label: str, file: bool = False) -> dict[str, str]:
    """Return the acceptance identity; `file` names the run-relative source."""
    expected = set(IDENTITY_FIELDS) | ({"file"} if file else set())
    require(isinstance(value, dict) and set(value) == expected,
            "%s must contain exactly %s" % (label, ", ".join(sorted(expected))))
    for field in sorted(expected):
        require(isinstance(value[field], str) and value[field].strip(),
                "%s.%s must be non-empty text" % (label, field))
    return {field: value[field] for field in IDENTITY_FIELDS}


def named(identities: dict[str, Any], field: str) -> dict[str, Any]:
    value = identities.get(field)
    require(isinstance(value, dict), "review/identities.json %s must be an object" % field)
    return value


def source_file(directory: Path, relative: str, label: str) -> Path:
    """Prefer a normalized transcript when the run recorded one beside the raw."""
    path = under(directory, relative, label)
    normalized = path.with_name(path.stem + ".normalized" + path.suffix)
    if normalized.is_file() and not normalized.is_symlink():
        return normalized
    return regular_file(path, label)


def staged_name(name: str, label: str) -> str:
    require(STAGED_NAME.fullmatch(name), "%s produces an uncontrolled published name: %s" % (label, name))
    return name


class Staged:
    """The staged tree: repository-relative paths written under one directory."""

    def __init__(self, directory: Path):
        self.directory = directory
        self.digests: dict[str, str] = {}

    def write(self, target: str, data: bytes) -> str:
        require(target not in self.digests, "duplicate staged target: %s" % target)
        runner.atomic(self.directory / target, data)
        self.digests[target] = runner.digest_bytes(data)
        return target


def audit_fields(text: str, label: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in validator._outside_fences(text):
        match = AUDIT_FIELD.match(line)
        if match:
            field = match.group(1).lower()
            require(field not in fields, "%s repeats audit field %s" % (label, field))
            fields[field] = match.group(2)
    for field in AUDIT_FIELDS:
        require(field in fields, "%s is missing audit field %s outside a fence" % (label, field))
    return fields


def declarations(decision: str, kind: str) -> dict[str, str]:
    section = validator._section(validator._current_decision(decision), "## Parameters")
    found: dict[str, str] = {}
    for line in validator._outside_fences(section):
        match = DECLARATION.match(line)
        if match and match.group(1) == kind:
            require(match.group(2) not in found, "DECISION.md repeats %s %s" % (kind, match.group(2)))
            found[match.group(2)] = match.group(3)
    return found


def decision_section(decision: str, heading: str, label: str) -> str:
    text = validator._section(validator._current_decision(decision), heading).strip()
    require(text, "DECISION.md needs a non-empty '%s' for %s" % (heading, label))
    return text


def reverify_of(decision: str) -> str:
    section = validator._section(validator._current_decision(decision), "## Decision")
    triggers = [line.strip() for line in validator._outside_fences(section) if line.strip().startswith("re-verify:")]
    require(len(triggers) == 1, "current '## Decision' needs exactly one 're-verify:' line")
    value = triggers[0][len("re-verify:"):].strip()
    require(value and triggers[0] == "re-verify: " + value, "re-verify must be written as 're-verify: <value>'")
    return value


def registry_of(root: Path) -> dict[str, dict[str, str]]:
    errors: list[str] = []
    registry = validator._parse_parameters(root, errors)
    require(not errors, "cannot read docs/port/PARAMETERS.md: " + "; ".join(errors))
    require(registry, "docs/port/PARAMETERS.md has no parameter rows")
    return registry


def resolve_index(root: Path, key: str) -> str:
    """Mark the item resolved in the index, changing only its status cell."""
    lines = text_of(root / "research/CLAUDE.md", "research/CLAUDE.md").splitlines(keepends=True)
    header, changed = None, 0
    for number, line in enumerate(lines):
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if header is None:
            if {"id", "status"} <= set(cells):
                require(cells[-1] == "status", "research index: status must be the last column")
                header = cells
            continue
        if cells and cells[0] == key:
            require(len(cells) == len(header), "research index: %s row does not match the header" % key)
            require(STATUS_CELL.search(line), "research index: %s status '%s' cannot become resolved" % (key, cells[-1]))
            lines[number] = STATUS_CELL.sub(r"| resolved |\1", line)
            changed += 1
    require(header is not None, "research index: no table header")
    require(changed == 1, "research index: expected exactly one %s row, found %d" % (key, changed))
    return "".join(lines)


def publish_values(root: Path, key: str, owns: dict[str, str], registry: dict[str, dict[str, str]]) -> str:
    """Copy every owned decision value into its registry row's value column."""
    lines = text_of(root / "docs/port/PARAMETERS.md", "docs/port/PARAMETERS.md").splitlines(keepends=True)
    columns, changed = None, {name: 0 for name in owns}
    for number, line in enumerate(lines):
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if columns is None:
            if {"param", "kind", "owner", "value"} <= set(cells):
                columns = {name: position for position, name in enumerate(cells)}
            continue
        name = cells[columns["param"]] if len(cells) > columns["param"] else ""
        if name not in owns:
            continue
        value = owns[name]
        require("|" not in value and value.strip() and value != "—",
                "DECISION.md value for %s cannot be published in the registry table: %r" % (name, value))
        require(cells[columns["kind"]] == "researched" and cells[columns["owner"]] == key,
                "docs/port/PARAMETERS.md: %s is not a researched parameter owned by %s" % (name, key))
        parts = line.split("|")
        parts[columns["value"] + 1] = " %s " % value
        lines[number] = "|".join(parts)
        changed[name] += 1
    require(columns is not None, "docs/port/PARAMETERS.md: no table header")
    for name, count in sorted(changed.items()):
        require(count == 1, "docs/port/PARAMETERS.md: expected exactly one %s row, found %d" % (name, count))
    return "".join(lines)


def prerequisite_hash(root: Path, key: str) -> str:
    require(runner.resolved(root, key), "prerequisite %s is not an accepted resolved topic" % key)
    digest = runner.sha(runner.topic_dir(root, key) / "DECISION.md")
    require(digest != "missing", "prerequisite %s has no DECISION.md" % key)
    return digest


def consumed_owners(root: Path, key: str, prompt: str) -> dict[str, str]:
    """Map each consumed parameter to the R## item whose decision owns it."""
    owners: dict[str, str] = {}
    for line in runner.coupling_lines(prompt):
        if line.startswith("- consumes:"):
            for owner, name in re.findall(r"(R[0-9]{2})\s*:\s*([a-z0-9-]+)", line.split(":", 1)[1]):
                require(name not in owners, "%s prompt consumes %s twice" % (key, name))
                require(owner != key, "%s prompt consumes its own parameter %s" % (key, name))
                owners[name] = owner
    _, expected = validator._prompt_parameters(prompt)
    require(set(owners) == expected, "%s prompt consumes values without an R## owner" % key)
    return owners


def empty_directory(value: str) -> Path:
    """A used staged directory is refused: a partial rebuild must never leave a
    superseded manifest.json standing beside freshly overwritten evidence."""
    directory = Path(value)
    if directory.exists():
        if not directory.is_dir() or directory.is_symlink():
            raise UsageError("--staged-dir must be a directory: %s" % value)
        require(not any(directory.iterdir()),
                "staged directory already holds a staged tree; package into an empty directory: %s" % value)
    return directory


def build(args: argparse.Namespace, root: Path) -> dict[str, Any]:
    staged_directory = empty_directory(args.staged_dir)
    key = runner.item(args.item)
    entry = runner.policy(root)["items"].get(key)
    require(isinstance(entry, dict), "%s absent from execution policy" % key)
    require(set(entry) == {"tier", "engines", "evidence_checks", "acceptance_after"},
            "%s execution policy record is malformed" % key)
    directory, _ = runner.load_manifest(root, key, args.run_id)
    prompt_file = runner.prompt_path(root, key)
    saved = regular_file(runner.under(directory, "inputs/prompt.md"), "prepared prompt copy")
    require(saved.read_bytes() == prompt_file.read_bytes(),
            "the prepared prompt copy differs from the current prompt; prepare a new run")
    prompt = text_of(prompt_file, "%s prompt" % key)
    topic = str(runner.topic_dir(root, key).relative_to(root))

    identities = runner.read_json(regular_file(runner.under(directory, "review/identities.json"), "review/identities.json"))
    require(isinstance(identities, dict) and set(identities) == IDENTITIES_FIELDS,
            "review/identities.json must contain exactly %s" % ", ".join(sorted(IDENTITIES_FIELDS)))

    decision_file = regular_file(runner.under(directory, "review/DECISION.md"), "review/DECISION.md")
    decision_bytes = decision_file.read_bytes()
    decision_text = text_of(decision_file, "review/DECISION.md")
    decision_sha = runner.digest_bytes(decision_bytes)

    staged = Staged(staged_directory)
    staged.write("%s/DECISION.md" % topic, decision_bytes)

    reports = []
    for field, engines in (("engine_reports", entry["engines"]), ("evidence_checks", entry["evidence_checks"])):
        recorded = named(identities, field)
        require(sorted(recorded) == sorted(engines),
                "review/identities.json %s must cover exactly %s" % (field, ", ".join(engines) or "no engine"))
        collected = []
        for engine in engines:
            label = "review/identities.json %s.%s" % (field, engine)
            who = identity(recorded[engine], label, file=True)
            source = source_file(directory, recorded[engine]["file"], label)
            target = "%s/raw/%s" % (topic, staged_name("%s-%s.md" % (engine, args.run_id), label))
            collected.append({"engine": engine, "path": staged.write(target, source.read_bytes()),
                              "sha256": staged.digests[target], "identity": who})
        reports.append(collected)
    engine_reports, evidence_checks = reports

    audits, executed_by = [], None
    recorded_audits = named(identities, "audits")
    require(set(recorded_audits) == set(AUDIT_FILES),
            "review/identities.json audits must contain exactly empirical, judgment")
    for kind in ("empirical", "judgment"):
        label = "review/identities.json audits.%s" % kind
        who = identity(recorded_audits[kind], label, file=True)
        source = regular_file(under(directory, recorded_audits[kind]["file"], label), "%s audit" % kind)
        fields = audit_fields(text_of(source, "%s audit" % kind), "%s audit" % kind)
        require(fields["decision-sha256"] == decision_sha,
                "%s audit is not bound to the run's DECISION.md" % kind)
        for field in ("actor", "model", "family"):
            require(fields[field] == who[field],
                    "%s audit records %s '%s', not the recorded identity '%s'" % (kind, field, fields[field], who[field]))
        require(fields["verdict"] == "approve", "%s audit verdict is '%s', not approve" % (kind, fields["verdict"]))
        require(fields["unresolved-findings"] == "none",
                "%s audit has unresolved findings: %s" % (kind, fields["unresolved-findings"]))
        target = "%s/%s" % (topic, AUDIT_FILES[kind])
        audits.append({"kind": kind, "path": staged.write(target, source.read_bytes()),
                       "sha256": staged.digests[target], "identity": who, "decision_sha256": decision_sha,
                       "verdict": "approve", "unresolved_findings": []})
        if kind == "empirical":
            executed_by = who

    evidence = under(directory, "review/evidence", "review/evidence")
    logs = sorted(path for path in evidence.glob("*.log") if path.is_file() and not path.is_symlink())
    require(logs, "missing required evidence logs under review/evidence/")
    staged_logs = {}
    for log in logs:
        name = staged_name("%s-%s" % (args.run_id, log.name), "review/evidence/%s" % log.name)
        staged_logs[log.name] = staged.write("%s/evidence/%s" % (topic, name), log.read_bytes())

    empirical = identities["empirical"]
    require(isinstance(empirical, dict) and set(empirical) == EMPIRICAL_FIELDS,
            "review/identities.json empirical must contain exactly %s" % ", ".join(sorted(EMPIRICAL_FIELDS)))
    require(isinstance(empirical["argv"], list) and empirical["argv"]
            and all(isinstance(word, str) and word for word in empirical["argv"]),
            "review/identities.json empirical.argv must be a non-empty string argv")
    for field in ("cwd", "toolchain"):
        require(isinstance(empirical[field], str) and empirical[field].strip(),
                "review/identities.json empirical.%s must be non-empty text" % field)
    require(empirical["exit_code"] == 0 and type(empirical["exit_code"]) is int,
            "review/identities.json empirical.exit_code must be integer 0")
    output = under(directory, empirical["output_log"], "review/identities.json empirical.output_log")
    require(output.parent == evidence and output.name in staged_logs,
            "empirical output log is not a staged review/evidence log: %s" % empirical["output_log"])

    owns = declarations(decision_text, "owns")
    registry = registry_of(root)
    fixed = {}
    for name, row in sorted(registry.items()):
        if row["kind"] == "fixed":
            require(row["value"] and row["value"] != "—", "registry %s has no fixed value" % name)
            fixed[name] = row["value"]
    research = {name: prerequisite_hash(root, name) for name in sorted(runner.research_prereqs(root, key))}
    consumed = {}
    for name, owner in sorted(consumed_owners(root, key, prompt).items()):
        require(owner in research, "%s consumes %s but %s is not a research prerequisite" % (key, name, owner))
        published = declarations(text_of(runner.topic_dir(root, owner) / "DECISION.md", "%s DECISION.md" % owner), "owns")
        require(name in published, "%s DECISION.md does not own the consumed parameter %s" % (owner, name))
        require(published[name] == registry.get(name, {}).get("value"),
                "%s DECISION.md value for %s differs from the current registry" % (owner, name))
        consumed[name] = published[name]

    acceptance = {
        "item": key,
        "schema_version": 1,
        "decision_sha256": decision_sha,
        "prompt_sha256": runner.digest_bytes(saved.read_bytes()),
        "policy_snapshot": entry,
        "engine_reports": engine_reports,
        "evidence_checks": evidence_checks,
        "synthesis": identity(identities["synthesis"], "review/identities.json synthesis"),
        "audits": audits,
        "empirical": {"argv": list(empirical["argv"]), "cwd": empirical["cwd"], "toolchain": empirical["toolchain"],
                      "output_log": staged_logs[output.name], "output_sha256": staged.digests[staged_logs[output.name]],
                      "exit_code": 0, "executed_by": executed_by},
        "parameters": {"consumed": consumed, "fixed": fixed},
        "prerequisites": {"research": research,
                          "acceptance_after": {name: prerequisite_hash(root, name)
                                               for name in sorted(entry.get("acceptance_after", []))}},
        "reverify": reverify_of(decision_text),
        "engines": decision_section(decision_text, "## Engines", "the engine disagreement record"),
        "principles": decision_section(decision_text, "### Principles and implementation", "the selected principles"),
    }
    acceptance_target = staged.write("%s/acceptance.json" % topic,
                                     (json.dumps(acceptance, indent=2, sort_keys=True) + "\n").encode())
    staged.write("research/CLAUDE.md", resolve_index(root, key).encode())
    staged.write("docs/port/PARAMETERS.md", publish_values(root, key, owns, registry).encode())

    changes = []
    for target in sorted(staged.digests):
        current = runner.sha(runner.under(root, target))
        if current != staged.digests[target]:
            changes.append({"target": target, "expected_sha256": current, "staged": target})
    require(changes, "the staged tree matches the repository; there is nothing to publish")
    manifest = staged.directory / "manifest.json"
    runner.write_json(manifest, {"item": key, "run_id": args.run_id, "dependency_hashes": {}, "changes": changes})
    return {"manifest": str(manifest), "changes": len(changes),
            "acceptance_sha256": staged.digests[acceptance_target]}


def parser() -> argparse.ArgumentParser:
    p = Parser(description=__doc__, allow_abbrev=False)
    p.add_argument("command", choices=("build",), help="assemble a staged publication from one run")
    p.add_argument("--root")
    p.add_argument("--item", required=True)
    p.add_argument("--run-id", required=True)
    p.add_argument("--staged-dir", required=True, help="directory receiving the staged tree and manifest.json")
    add_common_arguments(p, VERSION)
    return p


def main(argv: list[str] | None = None) -> int:
    raw_argv = list(sys.argv[1:] if argv is None else argv)
    try:
        args = parse_args(parser(), raw_argv)
        root = runner.root_from(args.root)
        result = build(args, root)
        diagnostic(args, "local offline packaging completed", level=1)
        envelope = {"ok": True, "result": result}
        if args.json: print(json.dumps(envelope, sort_keys=True))
        else: print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (PackageError, runner.RunnerError, UsageError, OSError, ValueError, TypeError, KeyError, AttributeError) as exc:
        return emit_error(exc, raw_argv, code="refused")
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__": raise SystemExit(main())
