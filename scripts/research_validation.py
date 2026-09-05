#!/usr/bin/env python3
"""P02 research evidence validators; CLI readers coordinate with publication.

The module deliberately validates recorded evidence, identity and hashes.  It
does not claim that an on-disk log proves a command actually ran; the empirical
and audit records make that claim reviewable by people and independent runners.
"""
from __future__ import print_function

import argparse
from contextlib import ExitStack
import hashlib
import json
import re
import sys
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
from research_cli import Parser, UsageError, add_common_arguments, diagnostic, emit_error, evidence_read_lock, parse_args


IDS = re.compile(r"^R[0-9]{2}$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
TIERS = {"light", "focused", "deep"}
ENGINE_SETS = {
    "light": ["codex"],
    "focused": ["codex", "opus"],
    "deep": ["codex", "opus", "doxa"],
}
CRATE_FIELDS = [
    "Landscape", "Principles and implementation", "Dominant choice",
    "Qualified shortlist", "Excluded by gate", "Up-and-comers",
    "Fit for this template", "Recommendation", "Ranked runner-up",
    "Tradeoffs", "Parameters", "Migration implications",
    "Validation strategy", "Confidence & re-verify trigger", "Sources",
]
PATTERN_FIELDS = ["Options" if x == "Qualified shortlist" else x for x in CRATE_FIELDS]
BUNDLE_FIELDS = [
    "Landscape", "Principles and implementation", "Recommendation", "Members",
    "Compatibility", "Parameters", "Migration implications", "Validation strategy",
    "Confidence & re-verify trigger", "Sources",
]
OVERRIDE_FIELDS = ["Inherited default", "Rust-specific argument", "Options rejected", "Override justified", "Resulting verdict"]


def _is_int(value):
    return isinstance(value, int) and not isinstance(value, bool)


def _read(path, errors, label):
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        errors.append("%s: cannot read %s" % (label, exc))
        return ""


def _inside(root, path, errors, label):
    try:
        resolved = path.resolve(strict=True)
        resolved.relative_to(root.resolve(strict=True))
    except (OSError, ValueError) as exc:
        errors.append("%s: path escapes repository or is unreadable: %s" % (label, path))
        return None
    return resolved


def _sha(path, errors, label):
    resolved = _inside(path.parent, path, errors, label)
    if resolved is None:
        return None
    try:
        return hashlib.sha256(resolved.read_bytes()).hexdigest()
    except OSError as exc:
        errors.append("%s: cannot hash %s" % (label, exc))
        return None


def _index(root, errors):
    path = root / "research" / "CLAUDE.md"
    text = _read(path, errors, "research index")
    rows, header = {}, None
    required = {"id", "slug", "kind", "origin", "verdict", "owns", "prompt", "status"}
    for line in text.splitlines():
        cells = [part.strip() for part in line.strip().strip("|").split("|")]
        if set(cells) >= required:
            header = {name: position for position, name in enumerate(cells)}
            continue
        if header is None or len(cells) < len(header):
            continue
        item = cells[header["id"]]
        if not IDS.match(item):
            continue
        if item in rows:
            errors.append("research index: duplicate item %s" % item)
        rows[item] = {name: cells[position] for name, position in header.items()}
    if not rows:
        errors.append("research index: no R## rows")
    return rows


def _prompt_path(root, row):
    match = re.search(r"\]\(([^)]+)\)", row["prompt"])
    if not match:
        return None
    return root / "research" / match.group(1)


def _line_states(text):
    """Return (line, fenced) pairs; delimiter lines are not answer content.

    CommonMark fences use at least three identical backticks or tildes. A
    shorter run, the other marker, or an info string cannot close a fence.
    """
    result, marker, width = [], None, 0
    for line in text.splitlines():
        match = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if marker is None:
            if match and not (match[1][0] == "`" and "`" in match[2]):
                marker, width = match[1][0], len(match[1])
                result.append(("", True))
            else:
                result.append((line, False))
        elif (match and match[1][0] == marker and len(match[1]) >= width
              and not match[2].strip()):
            result.append(("", True))
            marker, width = None, 0
        else:
            result.append((line, True))
    return result


def _headings_with_bodies(text, prefix):
    found = []
    lines = _line_states(text)
    level = len(prefix.rstrip())
    for number, (line, fenced) in enumerate(lines):
        if fenced or not line.startswith(prefix):
            continue
        body = []
        for next_line, next_fenced in lines[number + 1:]:
            heading = re.match(r"^(#{1,6})[ \t]+", next_line) if not next_fenced else None
            if heading:
                if len(heading[1]) <= level:
                    break
                continue
            content = next_line.strip()
            if content and not (not next_fenced and re.fullmatch(r"<!--.*-->", content)):
                body.append(content)
        found.append((line[len(prefix):].strip(), bool(body)))
    return found


def _outside_fences(text):
    return [line for line, fenced in _line_states(text) if not fenced]


def _parse_parameters(root, errors):
    text = _read(root / "docs/port/PARAMETERS.md", errors, "parameter registry")
    header, values = None, {}
    for line in text.splitlines():
        cells = [part.strip() for part in line.strip().strip("|").split("|")]
        if {"param", "kind", "owner", "value"}.issubset(cells):
            header = {name: position for position, name in enumerate(cells)}
        elif header is not None and len(cells) >= len(header) and cells[header["param"]]:
            values[cells[header["param"]]] = {name: cells[position] for name, position in header.items()}
    return values


def _coupling_lines(text):
    lines = _outside_fences(text)
    try:
        begin = lines.index("## Couplings")
    except ValueError:
        return []
    end = next((i for i in range(begin + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    return lines[begin + 1:end]


def _prompt_dependencies(text, item, owners):
    research = set()
    for line in _coupling_lines(text):
        if line.startswith("- consumes:"):
            research.update(re.findall(r"\bR[0-9]{2}\b", line))
        elif not owners.get(item) and line.startswith("- related"):
            research.update(candidate for candidate in re.findall(r"\bR[0-9]{2}\b", line) if owners.get(candidate))
    research.discard(item)
    return research


def _prompt_parameters(text):
    fixed, consumed = set(), set()
    for line in _coupling_lines(text):
        if line.startswith("- consumes:"):
            payload = line.split(":", 1)[1]
            for owner, parameter in re.findall(r"(R[0-9]{2}|owner)\s*:\s*([a-z0-9-]+)", payload):
                (fixed if owner == "owner" else consumed).add(parameter)
    return fixed, consumed


def validate_answer_text(text, kind, override=False):
    """Return shape diagnostics for an answer, ignoring headings in fences."""
    if kind == "crate":
        expected = CRATE_FIELDS
    elif kind == "pattern":
        expected = PATTERN_FIELDS
    elif kind == "bundle":
        expected = BUNDLE_FIELDS
    else:
        return ["answer: kind %r is not crate|pattern|bundle" % kind]
    if override:
        expected = expected + OVERRIDE_FIELDS
    headings = _headings_with_bodies(text, "### ")
    names = [name for name, _ in headings]
    errors = []
    if names != expected:
        errors.append("answer: H3 fields must be exactly in order: %s" % " | ".join(expected))
    for name, nonempty in headings:
        if not nonempty:
            errors.append("answer: field '### %s' has an empty body" % name)
    if kind == "bundle":
        states = _line_states(text)
        start = next((i for i, (line, fenced) in enumerate(states)
                      if not fenced and line == "### Members"), None)
        if start is None:
            return errors
        end = next((i for i in range(start + 1, len(states))
                    if not states[i][1] and re.match(r"^#{1,3} ", states[i][0])), len(states))
        member_starts = [i for i in range(start + 1, end)
                         if not states[i][1] and states[i][0].startswith("#### ")]
        if not member_starts:
            errors.append("answer: bundle has no named '####' member inside '### Members'")
        names = [states[i][0][5:].strip() for i in member_starts]
        if any(not name for name in names) or len(names) != len(set(names)):
            errors.append("answer: bundle member names must be nonempty and distinct")
        for number, member_start in enumerate(member_starts):
            member_end = member_starts[number + 1] if number + 1 < len(member_starts) else end
            # Slice the original lines so fence delimiters remain available to
            # the shared body parser. State indexes preserve original line positions.
            section = "\n".join(text.splitlines()[member_start + 1:member_end])
            fields = _headings_with_bodies(section, "##### ")
            if [name for name, _ in fields] != CRATE_FIELDS:
                errors.append("answer: bundle member %r must contain the crate H5 fields in order" % names[number])
            for name, nonempty in fields:
                if not nonempty:
                    errors.append("answer: bundle member field '##### %s' has an empty body" % name)
        first_member = member_starts[0] if member_starts else end
        for number, (line, fenced) in enumerate(states):
            if not fenced and line.startswith("##### ") and not first_member < number < end:
                errors.append("answer: bundle H5 member field is outside a named member in '### Members'")
    return errors


def _json_file(root, relative, errors, label):
    path = root / relative
    resolved = _inside(root, path, errors, label)
    if resolved is None:
        return None
    try:
        def no_duplicates(pairs):
            result = {}
            for key, value in pairs:
                if key in result:
                    raise ValueError("duplicate JSON key %r" % key)
                result[key] = value
            return result
        value = json.loads(resolved.read_text(encoding="utf-8"), object_pairs_hook=no_duplicates)
    except (OSError, UnicodeError, ValueError) as exc:
        errors.append("%s: invalid JSON: %s" % (label, exc))
        return None
    return value


def _list_of_strings(value, label, errors, allow_empty=True):
    if not isinstance(value, list) or any(not isinstance(x, str) or not x for x in value):
        errors.append("%s must be an array of non-empty strings" % label)
        return []
    if not allow_empty and not value:
        errors.append("%s must not be empty" % label)
    if len(value) != len(set(value)):
        errors.append("%s contains duplicates" % label)
    return value


def _prompt_policy(text, item, policy, errors):
    lines = _outside_fences(text)
    try:
        begin = lines.index("## Couplings")
    except ValueError:
        errors.append("%s prompt: missing ## Couplings" % item)
        return
    end = next((i for i in range(begin + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    coupled = lines[begin + 1:end]
    values = {}
    for label in ("effort", "engines", "evidence-checks", "acceptance-after"):
        matches = [line[len("- " + label + ":"):].strip() for line in coupled if line.startswith("- " + label + ":")]
        if len(matches) != 1:
            errors.append("%s prompt: Couplings needs exactly one '- %s:'" % (item, label))
        else:
            values[label] = matches[0]
    if values.get("effort") != policy["tier"]:
        errors.append("%s prompt: effort does not match EXECUTION.json" % item)
    def csv(value):
        return [x.strip() for x in value.split(",") if x.strip()] if isinstance(value, str) else []
    engines = csv(values.get("engines", ""))
    if engines != policy["engines"]:
        errors.append("%s prompt: engines do not match EXECUTION.json" % item)
    checks = csv(values.get("evidence-checks", ""))
    if checks != policy["evidence_checks"]:
        errors.append("%s prompt: evidence-checks do not match EXECUTION.json" % item)
    after = csv(values.get("acceptance-after", ""))
    if after != policy["acceptance_after"]:
        errors.append("%s prompt: acceptance-after does not match EXECUTION.json" % item)


def _cycle(edges, label, errors):
    """Report one directed cycle, where edges are prerequisite -> consumer."""
    visiting, visited, stack = set(), set(), []
    children = {}
    for left, right in edges:
        children.setdefault(left, []).append(right)
    def walk(node):
        if node in visiting:
            begin = stack.index(node)
            errors.append("%s graph has cycle: %s" % (label, " -> ".join(stack[begin:] + [node])))
            return True
        if node in visited:
            return False
        visiting.add(node); stack.append(node)
        for child in children.get(node, []):
            if walk(child): return True
        stack.pop(); visiting.remove(node); visited.add(node)
        return False
    for node in sorted(set(x for edge in edges for x in edge)):
        if walk(node):
            return


def validate_execution_policy(root):
    """Validate the current index, execution policy, and prompt policy mirrors."""
    root = Path(root)
    errors = []
    rows = _index(root, errors)
    data = _json_file(root, "research/EXECUTION.json", errors, "research/EXECUTION.json")
    if not isinstance(data, dict):
        errors.append("research/EXECUTION.json must be a JSON object")
        return errors
    if data.get("schema_version") != 1 or not _is_int(data.get("schema_version")):
        errors.append("research/EXECUTION.json: schema_version must be integer 1")
    if not isinstance(data.get("approved_on"), str) or not re.match(r"^\d{4}-\d{2}-\d{2}$", data.get("approved_on", "")):
        errors.append("research/EXECUTION.json: approved_on must be YYYY-MM-DD")
    pilot = data.get("pilot")
    if not isinstance(pilot, str) or pilot not in rows:
        errors.append("research/EXECUTION.json: pilot must name a current item")
    items = data.get("items")
    if not isinstance(items, dict):
        errors.append("research/EXECUTION.json: items must be an object")
        return errors
    missing = sorted(set(rows) - set(items))
    unknown = sorted(set(items) - set(rows))
    if missing:
        errors.append("research/EXECUTION.json: missing policy for %s" % ", ".join(missing))
    if unknown:
        errors.append("research/EXECUTION.json: unknown policy items %s" % ", ".join(unknown))
    prompt_texts = {}
    for item in sorted(set(rows) & set(items)):
        record = items[item]
        label = "research/EXECUTION.json %s" % item
        if not isinstance(record, dict):
            errors.append("%s must be an object" % label)
            continue
        required = {"tier", "engines", "evidence_checks", "acceptance_after"}
        if set(record) != required:
            errors.append("%s must contain exactly %s" % (label, ", ".join(sorted(required))))
            continue
        tier = record["tier"]
        if not isinstance(tier, str) or tier not in TIERS:
            errors.append("%s tier must be light|focused|deep" % label)
            continue
        engines = _list_of_strings(record["engines"], label + ".engines", errors, False)
        expected_engines = ENGINE_SETS[tier]
        if item == pilot:
            expected_engines = ["codex", "opus", "doxa"]
        if engines != expected_engines:
            errors.append("%s engines must be %s" % (label, ", ".join(expected_engines)))
        checks = _list_of_strings(record["evidence_checks"], label + ".evidence_checks", errors)
        expected_checks = ["terra"] if tier == "light" else []
        if checks != expected_checks:
            errors.append("%s evidence_checks must be %s" % (label, ", ".join(expected_checks) or "empty"))
        after = _list_of_strings(record["acceptance_after"], label + ".acceptance_after", errors)
        for prerequisite in after:
            if prerequisite not in rows or prerequisite == item:
                errors.append("%s acceptance_after has invalid item %r" % (label, prerequisite))
        prompt = _prompt_path(root, rows[item])
        if prompt is None or _inside(root, prompt, errors, item + " prompt") is None:
            continue
        prompt_texts[item] = _read(prompt, errors, item + " prompt")
        _prompt_policy(prompt_texts[item], item, record, errors)
    # The research graph deliberately includes only consumes and the documented
    # non-owner related-to-owner rule. Acceptance-after has its own graph.
    owners = {}
    for item, text in prompt_texts.items():
        for line in _coupling_lines(text):
            if line.startswith("- owns:"):
                for parameter in line.split(":", 1)[1].split(","):
                    parameter = parameter.strip()
                    if parameter:
                        owners.setdefault(item, set()).add(parameter)
    research_edges, acceptance_edges = [], []
    for item, text in prompt_texts.items():
        lines = _coupling_lines(text)
        for line in lines:
            if line.startswith("- consumes:"):
                for prerequisite in re.findall(r"\bR[0-9]{2}\b", line):
                    if prerequisite in rows and prerequisite != item:
                        research_edges.append((prerequisite, item))
            if not owners.get(item) and line.startswith("- related"):
                for prerequisite in re.findall(r"\bR[0-9]{2}\b", line):
                    if prerequisite != item and owners.get(prerequisite):
                        research_edges.append((prerequisite, item))
        policy = items.get(item)
        if isinstance(policy, dict) and isinstance(policy.get("acceptance_after"), list):
            for prerequisite in policy["acceptance_after"]:
                if isinstance(prerequisite, str) and prerequisite in rows and prerequisite != item:
                    acceptance_edges.append((prerequisite, item))
    _cycle(research_edges, "research", errors)
    _cycle(acceptance_edges, "acceptance", errors)
    _cycle(research_edges + acceptance_edges, "combined research/acceptance", errors)
    return errors


def validate_dependency_graphs(root):
    """Return only research/acceptance graph diagnostics for queue admission."""
    return [error for error in validate_execution_policy(root) if "graph" in error]


def _require_hash(value, label, errors):
    if not isinstance(value, str) or not SHA256.match(value):
        errors.append("%s must be a lowercase SHA-256" % label)


def _identity(value, label, errors):
    if not isinstance(value, dict) or set(value) != {"actor", "model", "family"}:
        errors.append("%s must contain actor, model and family" % label)
        return None
    for key in ("actor", "model", "family"):
        if not isinstance(value[key], str) or not value[key].strip():
            errors.append("%s.%s must be non-empty text" % (label, key))
    return value


def _artifact(root, value, label, errors):
    if not isinstance(value, dict) or set(value) != {"path", "sha256", "identity"}:
        errors.append("%s must contain path, sha256 and identity" % label)
        return None
    rel = value.get("path")
    if not isinstance(rel, str) or rel.startswith("/") or ".." in Path(rel).parts:
        errors.append("%s.path must be a confined relative path" % label)
    else:
        path = root / rel
        resolved = _inside(root, path, errors, label + ".path")
        if resolved and _sha(resolved, errors, label + ".path") != value.get("sha256"):
            errors.append("%s.sha256 does not match file bytes" % label)
    _require_hash(value.get("sha256"), label + ".sha256", errors)
    return _identity(value.get("identity"), label + ".identity", errors)


def _current_decision(text):
    lines = text.splitlines()
    stop = next((i for i, (line, fenced) in enumerate(_line_states(text))
                 if not fenced and line == "## Supersedes"), len(lines))
    return "\n".join(lines[:stop])


def _section(text, heading):
    states = _line_states(text)
    start = next((i for i, (line, fenced) in enumerate(states)
                  if not fenced and line == heading), None)
    if start is None:
        return ""
    level = len(heading.split(" ", 1)[0])
    end = next((i for i in range(start + 1, len(states))
                if not states[i][1] and re.match(r"^#{1,%d} " % level, states[i][0])), len(states))
    return "\n".join(text.splitlines()[start + 1:end])


def _validate_decision_text(text, item, acceptance, errors):
    current_text = _current_decision(text)
    current = _headings_with_bodies(current_text, "## ")
    expected = ["Decision", "Parameters", "Empirical check", "Engines"]
    if [heading for heading, _ in current] != expected:
        errors.append("%s DECISION.md current entry must have H2s Decision, Parameters, Empirical check, Engines in order before Supersedes" % item)
    for heading, nonempty in current:
        if not nonempty:
            errors.append("%s DECISION.md current '## %s' is empty" % (item, heading))
    decision = _section(current_text, "## Decision")
    principle_fields = [nonempty for name, nonempty in _headings_with_bodies(decision, "### ")
                        if name == "Principles and implementation"]
    if principle_fields != [True]:
        errors.append("%s DECISION.md current Decision needs one non-empty '### Principles and implementation'" % item)
    expected_reverify = acceptance.get("reverify") if isinstance(acceptance, dict) else None
    triggers = [line.strip() for line in _outside_fences(decision) if line.strip().startswith("re-verify:")]
    if not isinstance(expected_reverify, str) or triggers != ["re-verify: " + expected_reverify]:
        errors.append("%s DECISION.md must record current 're-verify: %s'" % (item, expected_reverify))


def _audit_text_accepts(root, relative, audit, item, label, errors):
    if not isinstance(relative, str) or relative.startswith("/") or ".." in Path(relative).parts:
        errors.append("%s %s has an invalid audit path" % (item, label))
        return
    path = root / relative
    if _inside(root, path, errors, label) is None:
        return
    text = _read(path, errors, label)
    fields = {}
    analysis = []
    for line in _outside_fences(text):
        match = re.match(r"^(decision-sha256|actor|model|family|verdict|unresolved-findings):\s*(.*?)\s*$", line, re.I)
        if match:
            key = match.group(1).lower()
            if key in fields:
                errors.append("%s %s repeats audit field %s" % (item, label, key))
            fields[key] = match.group(2)
        elif line.strip() and not line.startswith("#"):
            analysis.append(line.strip())
    identity = audit.get("identity") if isinstance(audit, dict) else {}
    expected = {"decision-sha256": audit.get("decision_sha256"), "actor": identity.get("actor") if isinstance(identity, dict) else None, "model": identity.get("model") if isinstance(identity, dict) else None, "family": identity.get("family") if isinstance(identity, dict) else None, "verdict": "approve", "unresolved-findings": "none"}
    for key, value in expected.items():
        if fields.get(key) != value:
            errors.append("%s %s must record %s: %s outside a fence" % (item, label, key, value))
    if not analysis:
        errors.append("%s %s needs non-metadata analysis or evidence" % (item, label))


def _owners_for_rows(root, rows, errors):
    owners = {}
    for candidate, candidate_row in rows.items():
        prompt = _prompt_path(root, candidate_row)
        if prompt is None or _inside(root, prompt, errors, candidate + " prompt") is None:
            continue
        for line in _coupling_lines(_read(prompt, errors, candidate + " prompt")):
            if line.startswith("- owns:"):
                values = {value.strip() for value in line.split(":", 1)[1].split(",") if value.strip()}
                if values:
                    owners[candidate] = values
    return owners


def validate_topic(root, item):
    """Validate one resolved topic and its recorded resolved prerequisites."""
    root = Path(root)
    errors = validate_execution_policy(root)
    errors.extend(_validate_topic(root, item, set(), set()))
    return errors


def _validate_topic(root, item, checked, visiting):
    """Internal recursive topic validator; policy is checked by the public API."""
    if item in checked:
        return []
    if item in visiting:
        return ["topic acceptance recursion reached %s" % item]
    visiting.add(item)
    errors = []
    rows = _index(root, errors)
    if item not in rows:
        visiting.remove(item)
        return errors + ["topic %s is not in research/CLAUDE.md" % item]
    row = rows[item]
    prompt = _prompt_path(root, row)
    if prompt is None:
        visiting.remove(item)
        return errors + ["%s prompt link is invalid" % item]
    prompt_resolved = _inside(root, prompt, errors, item + " prompt")
    if prompt_resolved is None:
        visiting.remove(item)
        return errors
    topic = prompt.parent.parent
    if _inside(root, topic, errors, item + " topic") is None:
        visiting.remove(item)
        return errors
    acceptance = _json_file(root, topic.relative_to(root) / "acceptance.json", errors, item + " acceptance.json")
    if not isinstance(acceptance, dict):
        if acceptance is not None:
            errors.append("%s acceptance.json must be a JSON object" % item)
        visiting.remove(item)
        return errors
    required = {"item", "schema_version", "decision_sha256", "prompt_sha256", "policy_snapshot", "engine_reports", "evidence_checks", "synthesis", "audits", "empirical", "parameters", "prerequisites", "reverify", "engines", "principles"}
    if set(acceptance) != required:
        errors.append("%s acceptance.json must contain exactly %s" % (item, ", ".join(sorted(required))))
        visiting.remove(item)
        return errors
    if acceptance["item"] != item:
        errors.append("%s acceptance.json item does not match topic" % item)
    if acceptance["schema_version"] != 1 or not _is_int(acceptance["schema_version"]):
        errors.append("%s acceptance.json schema_version must be integer 1" % item)
    decision = topic / "DECISION.md"
    decision_resolved = _inside(root, decision, errors, item + " DECISION.md")
    if decision_resolved:
        if _sha(decision_resolved, errors, item + " DECISION.md") != acceptance["decision_sha256"]:
            errors.append("%s decision_sha256 does not match DECISION.md" % item)
        _validate_decision_text(_read(decision_resolved, errors, item + " DECISION.md"), item, acceptance, errors)
    _require_hash(acceptance["decision_sha256"], item + " decision_sha256", errors)
    actual_prompt = _sha(prompt_resolved, errors, item + " prompt")
    if actual_prompt and actual_prompt != acceptance["prompt_sha256"]:
        errors.append("%s prompt_sha256 does not match prompt" % item)
    _require_hash(acceptance["prompt_sha256"], item + " prompt_sha256", errors)
    policy_data = _json_file(root, "research/EXECUTION.json", [], "policy") or {}
    policy_items = policy_data.get("items") if isinstance(policy_data, dict) else {}
    policy = policy_items.get(item) if isinstance(policy_items, dict) else None
    if acceptance["policy_snapshot"] != policy:
        errors.append("%s policy_snapshot does not match current EXECUTION.json policy" % item)
    reports = acceptance["engine_reports"]
    if not isinstance(reports, list):
        errors.append("%s engine_reports must be an array" % item)
        reports = []
    expected_engines = policy.get("engines", []) if isinstance(policy, dict) else []
    seen_engines = []
    raw_identities = []
    producer_identities = []
    for number, report in enumerate(reports):
        if not isinstance(report, dict) or set(report) != {"engine", "path", "sha256", "identity"}:
            errors.append("%s engine_reports[%d] must contain engine, path, sha256 and identity" % (item, number))
            continue
        seen_engines.append(report["engine"])
        identity = _artifact(root, {"path": report["path"], "sha256": report["sha256"], "identity": report["identity"]}, "%s engine_reports[%d]" % (item, number), errors)
        report_path = root / report["path"] if isinstance(report["path"], str) else None
        if report_path and _inside(root, report_path, errors, "%s engine_reports[%d]" % (item, number)):
            errors.extend("%s engine_reports[%d]: %s" % (item, number, error) for error in validate_answer_text(_read(report_path, errors, "%s engine_reports[%d]" % (item, number)), row["kind"], "OVERRIDE" in row["verdict"]))
        raw_identities.append(identity)
        producer_identities.append(identity)
        if identity:
            expected_family = {"codex": "openai", "opus": "anthropic"}.get(report["engine"])
            if expected_family and identity["family"] != expected_family:
                errors.append("%s engine_reports[%d] %s family must be %s" % (item, number, report["engine"], expected_family))
            if report["engine"] == "doxa" and identity["family"] == "doxa":
                errors.append("%s engine_reports[%d] Doxa must record actual provider family composition, not 'doxa'" % (item, number))
    if seen_engines != expected_engines:
        errors.append("%s engine_reports must cover required engines in policy order" % item)
    raw_actors = [identity["actor"] for identity in raw_identities if identity]
    if len(raw_actors) != len(set(raw_actors)):
        errors.append("%s engine report actors must be distinct" % item)
    checks = acceptance["evidence_checks"]
    expected_checks = policy.get("evidence_checks", []) if isinstance(policy, dict) else []
    if not isinstance(checks, list):
        errors.append("%s evidence_checks must be an array" % item)
        checks = []
    seen_checks = []
    for number, check in enumerate(checks):
        if not isinstance(check, dict) or set(check) != {"engine", "path", "sha256", "identity"}:
            errors.append("%s evidence_checks[%d] must contain engine, path, sha256 and identity" % (item, number))
            continue
        seen_checks.append(check["engine"])
        identity = _artifact(root, {"path": check["path"], "sha256": check["sha256"], "identity": check["identity"]}, "%s evidence_checks[%d]" % (item, number), errors)
        if identity and any(raw and identity["actor"] == raw.get("actor") for raw in raw_identities):
            errors.append("%s evidence check actor produced raw research" % item)
        if identity and check["engine"] == "terra" and identity["family"] != "openai":
            errors.append("%s Terra evidence check family must be openai" % item)
        producer_identities.append(identity)
    if seen_checks != expected_checks:
        errors.append("%s evidence_checks must cover policy checks in order" % item)
    synthesis = _identity(acceptance["synthesis"], item + " synthesis", errors)
    if synthesis and synthesis["family"] != "anthropic":
        errors.append("%s synthesis family must be anthropic" % item)
    if synthesis and any(identity and synthesis["actor"] == identity.get("actor") for identity in producer_identities):
        errors.append("%s synthesis actor produced raw evidence" % item)
    audits = acceptance["audits"]
    if not isinstance(audits, list) or len(audits) != 2:
        errors.append("%s audits must contain exactly two revision-bound approve records" % item)
        audits = []
    auditor_families, auditor_actors, audit_kinds = [], [], []
    for number, audit in enumerate(audits):
        required_audit = {"kind", "path", "sha256", "identity", "decision_sha256", "verdict", "unresolved_findings"}
        if not isinstance(audit, dict) or set(audit) != required_audit:
            errors.append("%s audits[%d] has wrong fields" % (item, number))
            continue
        if audit["kind"] not in {"empirical", "judgment"} or audit["verdict"] != "approve" or audit["unresolved_findings"] != []:
            errors.append("%s audits[%d] must be an approve empirical/judgment audit with no unresolved findings" % (item, number))
        if audit["decision_sha256"] != acceptance["decision_sha256"]:
            errors.append("%s audits[%d] is not bound to current DECISION.md" % (item, number))
        expected_path = "%s/audit-%s.md" % (topic.relative_to(root), "codex" if audit["kind"] == "empirical" else "fable")
        if audit["path"] != expected_path:
            errors.append("%s audits[%d] must hash %s" % (item, number, expected_path))
        _audit_text_accepts(root, audit["path"], audit, item, "%s audits[%d]" % (item, number), errors)
        identity = _artifact(root, {"path": audit["path"], "sha256": audit["sha256"], "identity": audit["identity"]}, "%s audits[%d]" % (item, number), errors)
        if identity:
            auditor_families.append(identity["family"])
            auditor_actors.append(identity["actor"])
            audit_kinds.append(audit["kind"])
            if synthesis and identity["actor"] == synthesis["actor"]:
                errors.append("%s audits[%d] actor is the synthesizer" % (item, number))
            if any(producer and identity["actor"] == producer.get("actor") for producer in producer_identities):
                errors.append("%s audits[%d] actor produced evidence" % (item, number))
            required_family = "openai" if audit["kind"] == "empirical" else "anthropic"
            if identity["family"] != required_family:
                errors.append("%s audits[%d] %s family must be %s" % (item, number, audit["kind"], required_family))
    if len(auditor_families) == 2 and auditor_families[0] == auditor_families[1]:
        errors.append("%s auditors must use different model families" % item)
    if len(auditor_actors) == 2 and auditor_actors[0] == auditor_actors[1]:
        errors.append("%s audits must use different actors" % item)
    if sorted(audit_kinds) != ["empirical", "judgment"]:
        errors.append("%s audits must contain one empirical and one judgment audit" % item)
    empirical = acceptance["empirical"]
    required_empirical = {"argv", "cwd", "toolchain", "output_log", "output_sha256", "exit_code", "executed_by"}
    if not isinstance(empirical, dict) or set(empirical) != required_empirical:
        errors.append("%s empirical has wrong fields" % item)
    else:
        if not isinstance(empirical["argv"], list) or not empirical["argv"] or any(not isinstance(x, str) or not x for x in empirical["argv"]):
            errors.append("%s empirical.argv must be a non-empty string argv" % item)
        if not isinstance(empirical["cwd"], str) or not empirical["cwd"]:
            errors.append("%s empirical.cwd must be non-empty text" % item)
        if not isinstance(empirical["toolchain"], str) or not empirical["toolchain"]:
            errors.append("%s empirical.toolchain must be non-empty text" % item)
        if empirical["exit_code"] != 0 or not _is_int(empirical["exit_code"]):
            errors.append("%s empirical.exit_code must be integer 0" % item)
        identity = _identity(empirical["executed_by"], item + " empirical.executed_by", errors)
        if identity and synthesis and identity["family"] == synthesis["family"]:
            errors.append("%s empirical executor family must differ from synthesis family" % item)
        _artifact(root, {"path": empirical["output_log"], "sha256": empirical["output_sha256"], "identity": empirical["executed_by"]}, item + " empirical.output", errors)
        empirical_audit = next((audit for audit in audits if isinstance(audit, dict) and audit.get("kind") == "empirical"), None)
        if empirical_audit and empirical["executed_by"] != empirical_audit.get("identity"):
            errors.append("%s empirical.executed_by must equal the empirical audit identity" % item)
    params = acceptance["parameters"]
    if not isinstance(params, dict) or set(params) != {"consumed", "fixed"}:
        errors.append("%s parameters must contain consumed and fixed" % item)
    else:
        for key in ("consumed", "fixed"):
            if not isinstance(params[key], dict) or any(not isinstance(name, str) or not isinstance(value, str) or not value for name, value in params[key].items()):
                errors.append("%s parameters.%s must be string values" % (item, key))
        registry = _parse_parameters(root, errors)
        _, expected_consumed = _prompt_parameters(_read(prompt_resolved, errors, item + " prompt"))
        expected_fixed = {name for name, record in registry.items() if record.get("kind") == "fixed"}
        for key, expected in (("fixed", expected_fixed), ("consumed", expected_consumed)):
            actual = params.get(key, {}) if isinstance(params.get(key), dict) else {}
            if set(actual) != expected:
                errors.append("%s parameters.%s does not match current prompt couplings" % (item, key))
            for parameter in expected:
                value = registry.get(parameter, {}).get("value")
                if not value or value == "—" or actual.get(parameter) != value:
                    errors.append("%s parameters.%s.%s does not match current registry value" % (item, key, parameter))
        owners = _owners_for_rows(root, rows, errors)
        decision_text = _read(decision_resolved, errors, item + " DECISION.md") if decision_resolved else ""
        parameter_section = _section(_current_decision(decision_text), "## Parameters")
        declarations = {"owns": {}, "assumes": {}}
        for line in _outside_fences(parameter_section):
            match = re.match(r"^- (owns|assumes)\s+([a-z0-9-]+)\s*=\s*(.+?)\s*$", line)
            if match:
                kind, parameter, value = match.groups()
                if parameter in declarations[kind]:
                    errors.append("%s DECISION.md repeats %s %s" % (item, kind, parameter))
                declarations[kind][parameter] = value
        expected_owns = owners.get(item, set())
        if set(declarations["owns"]) != expected_owns:
            errors.append("%s DECISION.md current owned parameter set does not match prompt" % item)
        for parameter in expected_owns:
            value = registry.get(parameter, {}).get("value")
            if not value or value == "—" or declarations["owns"].get(parameter) != value:
                errors.append("%s DECISION.md owned %s does not match current registry value" % (item, parameter))
        expected_assumptions = expected_fixed | expected_consumed
        if set(declarations["assumes"]) != expected_assumptions:
            errors.append("%s DECISION.md current assumed parameter set does not match fixed and consumed values" % item)
        for parameter in expected_assumptions:
            if declarations["assumes"].get(parameter) != registry.get(parameter, {}).get("value"):
                errors.append("%s DECISION.md assumed %s does not match current registry value" % (item, parameter))
    prerequisites = acceptance["prerequisites"]
    if not isinstance(prerequisites, dict) or set(prerequisites) != {"research", "acceptance_after"}:
        errors.append("%s prerequisites must contain research and acceptance_after" % item)
    else:
        for key in ("research", "acceptance_after"):
            values = prerequisites[key]
            if not isinstance(values, dict):
                errors.append("%s prerequisites.%s must map item IDs to decision hashes" % (item, key))
            else:
                for prerequisite, digest in values.items():
                    if prerequisite not in rows:
                        errors.append("%s prerequisites.%s has unknown item %s" % (item, key, prerequisite))
                    _require_hash(digest, "%s prerequisites.%s.%s" % (item, key, prerequisite), errors)
                    if prerequisite in rows:
                        pre_prompt = _prompt_path(root, rows[prerequisite])
                        pre_decision = pre_prompt.parent.parent / "DECISION.md" if pre_prompt else None
                        current = _sha(pre_decision, errors, "%s prerequisite %s" % (item, prerequisite)) if pre_decision and _inside(root, pre_decision, errors, "%s prerequisite %s" % (item, prerequisite)) else None
                        if current and current != digest:
                            errors.append("%s prerequisites.%s.%s does not match current decision" % (item, key, prerequisite))
                        if rows[prerequisite]["status"] != "resolved":
                            errors.append("%s prerequisite %s is not resolved" % (item, prerequisite))
                        else:
                            errors.extend(_validate_topic(root, prerequisite, checked, visiting))
        expected_after = policy.get("acceptance_after", []) if isinstance(policy, dict) else []
        expected_after = expected_after if isinstance(expected_after, list) else []
        actual_after = prerequisites.get("acceptance_after", {}) if isinstance(prerequisites.get("acceptance_after", {}), dict) else {}
        if set(actual_after) != set(expected_after):
            errors.append("%s acceptance prerequisites do not match policy acceptance_after" % item)
        owners = _owners_for_rows(root, rows, errors)
        expected_research = _prompt_dependencies(_read(prompt_resolved, errors, item + " prompt"), item, owners)
        actual_research = prerequisites.get("research", {}) if isinstance(prerequisites.get("research", {}), dict) else {}
        if set(actual_research) != expected_research:
            errors.append("%s research prerequisites do not match current prompt graph" % item)
    for key in ("reverify", "engines", "principles"):
        if not isinstance(acceptance[key], str) or not acceptance[key].strip():
            errors.append("%s acceptance.json %s must be non-empty text" % (item, key))
    visiting.remove(item)
    checked.add(item)
    return errors


def _safe_public(validator):
    """Malformed untrusted JSON must become a diagnostic, never a traceback."""
    def wrapped(*args, **kwargs):
        try:
            return validator(*args, **kwargs)
        except (AttributeError, KeyError, TypeError, ValueError) as exc:
            return ["validator rejected malformed input: %s" % type(exc).__name__]
    return wrapped


validate_execution_policy = _safe_public(validate_execution_policy)
validate_topic = _safe_public(validate_topic)


def _main(argv):
    parser = Parser(description=__doc__)
    add_common_arguments(parser, "research-validation 0.1.0")
    parser.add_argument("--legacy-output", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--require-owner-review", action="store_true")
    parser.add_argument("--root", help="repository root; overrides config root")
    parser.add_argument("mode", choices=["answer", "tree", "topic", "check-tree"])
    parser.add_argument("paths", nargs="*")
    args = parse_args(parser, argv)
    if args.require_owner_review and args.mode != "check-tree":
        parser.error("--require-owner-review requires check-tree mode")
    with ExitStack() as locks:
        if args.mode == "answer":
            if len(args.paths) not in (2, 3) or (len(args.paths) == 3 and args.paths[2] != "override"):
                parser.error("answer needs ANSWER.md KIND [override]")
            try:
                text = Path(args.paths[0]).read_text(encoding="utf-8")
            except (OSError, UnicodeError) as exc:
                errors = ["answer: cannot read %s" % exc]
            else:
                errors = validate_answer_text(text, args.paths[1], len(args.paths) == 3)
        else:
            if args.mode in {"tree", "check-tree"}:
                if len(args.paths) == 0:
                    root = Path(args.root) if args.root else HERE.parent
                elif len(args.paths) == 1:
                    root = Path(args.paths[0])
                else:
                    parser.error("tree needs ROOT or --root/--config")
            else:
                if len(args.paths) == 1 and args.root:
                    root, key = Path(args.root), args.paths[0]
                elif len(args.paths) == 2:
                    root, key = Path(args.paths[0]), args.paths[1]
                else:
                    parser.error("topic needs ROOT ITEM or --root/--config ITEM")
            locks.enter_context(evidence_read_lock(root))
            errors = []
            if args.mode == "check-tree":
                core = HERE / "check-research-tree-core.sh"
                if not core.is_file() or core.is_symlink():
                    errors.append("missing or unsafe structural checker core")
                else:
                    command = ["/bin/bash", str(core)]
                    if args.require_owner_review:
                        command.append("--require-owner-review")
                    result = subprocess.run(command + [str(root)], capture_output=True, text=True)
                    if result.returncode:
                        errors.extend(line.removeprefix("FAIL: ") for line in (result.stdout + result.stderr).splitlines() if line.strip())
                        if not errors:
                            errors.append("structural checker failed with exit %d" % result.returncode)
            if not errors:
                if args.mode == "topic":
                    errors = validate_topic(root, key)
                else:
                    errors = validate_execution_policy(root)
                    for item, row in sorted(_index(root, []).items()):
                        if row["status"] == "resolved":
                            errors.extend(validate_topic(root, item))
        if not errors:
            diagnostic(args, "validation mode %s completed" % args.mode)
        if args.json:
            if errors:
                print(json.dumps({"error": {"code": "validation_failed", "message": "validation failed", "details": errors}}, sort_keys=True), file=sys.stderr)
            else:
                print(json.dumps({"ok": True}, sort_keys=True))
        elif errors:
            for error in errors:
                print(("FAIL: " if args.legacy_output else "error: ") + error,
                      file=sys.stdout if args.legacy_output else sys.stderr)
        else:
            print("OK: research tree structure valid" if args.mode == "check-tree" else "OK: validation passed")
        return 0 if not errors else 1


if __name__ == "__main__":
    try:
        sys.exit(_main(sys.argv[1:]))
    except (UsageError, OSError, RuntimeError) as exc:
        if "--legacy-output" in sys.argv[1:]:
            print("FAIL: " + str(exc))
            sys.exit(2 if isinstance(exc, UsageError) else 1)
        sys.exit(emit_error(exc, sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)
