#!/usr/bin/env python3
"""Offline, durable orchestration for the P02 research program.

This program deliberately has no provider adapter.  A short-lived worker records
what it intended to submit, then records the returned provider operation ID.
Another worker can collect that exact ID later.  It never turns uncertainty into
a second paid submission.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from research_cli import Parser, UsageError, add_common_arguments, diagnostic, emit_error, parse_args

VERSION = "0.1.0"
ITEM_RE = re.compile(r"R(?:0[1-9]|[1-9][0-9])$")
OPERATIONS = {"ready", "submitting", "unknown", "submitted", "running", "partial", "succeeded", "failed"}


class RunnerError(Exception): pass
class BusyError(RunnerError): pass


def now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def digest_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha(path: Path) -> str:
    return digest_bytes(path.read_bytes()) if path.exists() else "missing"


def atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data); f.flush(); os.fsync(f.fileno())
        os.replace(name, path)
        dfd = os.open(path.parent, os.O_RDONLY)
        try: os.fsync(dfd)
        finally: os.close(dfd)
    finally:
        if os.path.exists(name): os.unlink(name)


def write_json(path: Path, value: Any) -> None:
    atomic(path, (json.dumps(value, indent=2, sort_keys=True) + "\n").encode())


def read_json(path: Path) -> Any:
    try: return json.loads(path.read_text())
    except FileNotFoundError: raise RunnerError(f"missing required file: {path}")
    except json.JSONDecodeError as exc: raise RunnerError(f"invalid JSON: {path}: {exc}") from exc


def root_from(value: str | None) -> Path:
    start = Path(value or os.getcwd()).resolve()
    for candidate in (start, *start.parents):
        if (candidate / "research" / "CLAUDE.md").is_file() and (candidate / "docs" / "planning" / "p02").is_dir():
            return candidate
    raise UsageError("cannot locate repository root; pass --root")


def item(value: str) -> str:
    if not ITEM_RE.fullmatch(value): raise UsageError(f"invalid item: {value}")
    return value


def safe_relative(value: str) -> Path:
    if not isinstance(value, str): raise UsageError("relative path must be text")
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or not path.parts or str(path) != value:
        raise UsageError(f"unsafe relative path: {value}")
    return path


def under(root: Path, relative: str) -> Path:
    rel = safe_relative(relative); path = root
    for part in rel.parts:
        path = path / part
        if path.is_symlink(): raise UsageError(f"symlink component refused: {relative}")
    return path


class DirLock:
    """A lock that is never stolen. An operator must inspect/remove a stale lock."""
    def __init__(self, path: Path): self.path = path
    def __enter__(self):
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self.path.mkdir(parents=False)
            write_json(self.path / "owner.json", {"pid": os.getpid(), "at": now()})
        except FileExistsError: raise BusyError(f"active lock refused: {self.path}; it is never auto-stolen")
        return self
    def __exit__(self, *unused):
        shutil.rmtree(self.path)


def topic_dir(root: Path, key: str) -> Path:
    number = int(key[1:])
    choices = list((root / "research" / "topics").glob(f"{number:02d}-*"))
    if len(choices) != 1: raise RunnerError(f"cannot uniquely locate topic for {key}")
    return under(root, str(choices[0].relative_to(root)))


def prompt_path(root: Path, key: str) -> Path:
    choices = list((topic_dir(root, key) / "prompts").glob("*.prompt.md"))
    if len(choices) != 1: raise RunnerError(f"cannot uniquely locate prompt for {key}")
    return under(root, str(choices[0].relative_to(root)))


def run_dir(root: Path, key: str, run_id: str) -> Path:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,100}", run_id): raise UsageError("invalid run ID")
    return under(root, f"research/runs/{key}/{run_id}")


def policy(root: Path) -> dict[str, Any]:
    path = root / "research" / "EXECUTION.json"
    data = read_json(path)
    if data.get("schema_version") != 1 or not isinstance(data.get("items"), dict):
        raise RunnerError("research/EXECUTION.json must have schema_version 1 and items")
    return data


def validation_errors(root: Path, key: str | None = None) -> list[str]:
    path = root / "scripts" / "research_validation.py"
    if not path.is_file(): return ["missing required scripts/research_validation.py"]
    spec = importlib.util.spec_from_file_location("research_validation", path)
    if spec is None or spec.loader is None: return ["cannot load research_validation.py"]
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    errors = list(module.validate_execution_policy(root))
    if key is not None: errors.extend(module.validate_topic(root, key))
    return errors


def load_manifest(root: Path, key: str, run_id: str) -> tuple[Path, dict[str, Any]]:
    directory = run_dir(root, key, run_id)
    for relative in ("manifest.json", "inputs", "operations", "raw", ".lock"):
        under(directory, relative)
    manifest = read_json(under(directory, "manifest.json"))
    if manifest.get("item") != key or manifest.get("run_id") != run_id: raise RunnerError("run manifest identity mismatch")
    return directory, manifest


def save_manifest(directory: Path, manifest: dict[str, Any]) -> None:
    manifest["updated_at"] = now(); write_json(directory / "manifest.json", manifest)


def freshness_errors(root: Path, key: str, manifest: dict[str, Any]) -> list[str]:
    hashes = manifest.get("input_hashes", {})
    entry = policy(root)["items"][key]
    current = {"prompt": sha(prompt_path(root, key)), "policy_item": digest_bytes(json.dumps(entry, sort_keys=True).encode()), "parameters_semantic": digest_bytes(json.dumps(semantic_parameters(root, key), sort_keys=True).encode())}
    errors = [f"stale input snapshot: {name}" for name, value in current.items() if hashes.get(name) != value]
    directory = run_dir(root, key, manifest["run_id"])
    snapshots = {"prompt": "prompt.md", "policy": "EXECUTION.json", "registry": "CLAUDE.md", "parameters": "PARAMETERS.md", "prerequisites": "prerequisites.json", "parameters_semantic_file": "parameters.json"}
    for label, name in snapshots.items():
        if sha(under(directory, f"inputs/{name}")) != hashes.get(label):
            errors.append(f"modified immutable snapshot: {name}")
    saved = read_json(under(directory, "inputs/prerequisites.json"))
    if set(saved) != research_prereqs(root, key): errors.append("stale prerequisite snapshot keys")
    for prerequisite, recorded in saved.items():
        if recorded.get("decision") != sha(topic_dir(root, prerequisite) / "DECISION.md") or recorded.get("acceptance") != sha(topic_dir(root, prerequisite) / "acceptance.json"):
            errors.append(f"stale prerequisite snapshot: {prerequisite}")
    return errors


def semantic_parameters(root: Path, key: str) -> list[dict[str, str]]:
    """Only fixed and explicitly consumed values invalidate a prepared run."""
    text = "\n".join(coupling_lines(prompt_path(root, key).read_text()))
    consumed = set(re.findall(r"\bR\d\d:\s*([a-z0-9-]+)", text))
    selected = []
    for line in (root / "docs" / "port" / "PARAMETERS.md").read_text().splitlines():
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) == 5 and cells[0] not in {"param", "---"} and (cells[1] == "fixed" or cells[0] in consumed):
            selected.append({"param": cells[0], "kind": cells[1], "owner": cells[2], "value": cells[3]})
    return selected


def prepare(args: argparse.Namespace, root: Path) -> dict[str, Any]:
    key = item(args.item); p = policy(root); entry = p["items"].get(key)
    if not isinstance(entry, dict): raise RunnerError(f"{key} absent from execution policy")
    errors = validation_errors(root)
    if errors: raise RunnerError("execution policy invalid: " + "; ".join(errors))
    run_id = args.run_id or f"{datetime.now(timezone.utc):%Y-%m-%dT%H%M%SZ}-{uuid.uuid4().hex[:12]}"
    directory = run_dir(root, key, run_id)
    with DirLock(under(root, f"research/runs/.locks/{key}")):
        if directory.exists(): raise RunnerError(f"run directory collision: {directory}")
        pp = prompt_path(root, key); prompt = pp.read_bytes()
        directory.mkdir(parents=True); (directory / "inputs").mkdir(); (directory / "operations").mkdir(); (directory / "raw").mkdir(); (directory / "review").mkdir()
        atomic(directory / "inputs" / "prompt.md", prompt)
        snapshots = {"policy": root / "research" / "EXECUTION.json", "registry": root / "research" / "CLAUDE.md", "parameters": root / "docs" / "port" / "PARAMETERS.md"}
        parameters = semantic_parameters(root, key)
        snap = {"prompt": digest_bytes(prompt), "policy_item": digest_bytes(json.dumps(entry, sort_keys=True).encode()), "parameters_semantic": digest_bytes(json.dumps(parameters, sort_keys=True).encode())}
        for label, source in snapshots.items():
            data = source.read_bytes(); atomic(directory / "inputs" / source.name, data); snap[label] = digest_bytes(data)
        write_json(directory / "inputs" / "parameters.json", parameters)
        snap["parameters_semantic_file"] = sha(directory / "inputs" / "parameters.json")
        prerequisite_hashes = {}
        for prerequisite in sorted(research_prereqs(root, key)):
            prerequisite_hashes[prerequisite] = {"decision": sha(topic_dir(root, prerequisite) / "DECISION.md"), "acceptance": sha(topic_dir(root, prerequisite) / "acceptance.json")}
        write_json(directory / "inputs" / "prerequisites.json", prerequisite_hashes)
        snap["prerequisites"] = digest_bytes((directory / "inputs" / "prerequisites.json").read_bytes())
        manifest = {"schema_version": 1, "item": key, "run_id": run_id, "created_at": now(), "updated_at": now(),
                    "state": "ready", "actor": args.actor, "model": args.model, "authorization_ref": args.authorization_ref,
                    "remaining_budget": args.budget, "tier": entry.get("tier"), "required_engines": entry.get("engines", []),
                    "input_hashes": snap, "prompt_source": str(pp.relative_to(root)), "operations": {}, "events": [{"at": now(), "state": "ready", "actor": args.actor}]}
        save_manifest(directory, manifest)
    return {"item": key, "run_id": run_id, "state": "ready", "manifest": str((directory / "manifest.json").relative_to(root))}


def update_operation(args: argparse.Namespace, root: Path, action: str) -> dict[str, Any]:
    key = item(args.item); directory, manifest = load_manifest(root, key, args.run_id)
    provider = args.provider
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,30}", provider): raise UsageError("invalid provider")
    with DirLock(directory / ".lock"):
        directory, manifest = load_manifest(root, key, args.run_id); current = manifest["operations"].get(provider)
        if manifest.get("state") == "published": raise RunnerError("published run is immutable; prepare a new run for further work")
        if action == "intent":
            stale = freshness_errors(root, key, manifest)
            if stale: raise RunnerError("; ".join(stale))
            blocked = sorted(x for x in research_prereqs(root, key) if not resolved(root, x))
            if blocked: raise RunnerError(f"research prerequisites are not accepted: {', '.join(blocked)}")
            if current and current["state"] not in {"failed"}:
                raise RunnerError(f"duplicate submission refused for {provider}: {current['state']}")
            rec = {"provider": provider, "state": "submitting", "request_id": args.request_id or uuid.uuid4().hex, "actor": args.actor, "model": args.model, "at": now()}
        elif action == "submitted":
            if not current or current["state"] not in {"submitting", "unknown"}: raise RunnerError("operation must be submitting or unknown before an ID is recorded")
            if not args.operation_id: raise UsageError("--operation-id is required")
            rec = {**current, "state": "submitted", "operation_id": args.operation_id, "returned_at": now(), "actual_provider": args.actual_provider or provider, "actual_model": args.actual_model or args.model}
        elif action == "unknown":
            if not current or current["state"] != "submitting": raise RunnerError("only a submitting operation can become unknown")
            rec = {**current, "state": "unknown", "unknown_at": now(), "reason": args.reason}
        else:
            if not current or current["state"] in {"unknown", "failed"}: raise RunnerError("cannot collect unknown/failed operation; reconcile provider inventory first")
            if not current.get("operation_id"): raise RunnerError("cannot collect without operation ID")
            state = args.state
            if state not in {"running", "partial", "succeeded", "failed"}: raise UsageError("invalid collection state")
            rec = {**current, "state": state, "collected_at": now(), "reason": args.reason}
            if args.raw_file:
                source = under(directory, args.raw_file)
                if not source.is_file() or source.is_symlink(): raise RunnerError("raw file must be a regular file beneath this run")
                data = source.read_bytes(); destination = under(directory, f"raw/{provider}-{digest_bytes(data)}.md")
                if destination.exists() and destination.read_bytes() != data: raise RunnerError("immutable raw bytes changed")
                if not destination.exists(): atomic(destination, data)
                rec["raw"] = str(destination.relative_to(root)); rec["raw_sha256"] = digest_bytes(data)
        manifest["operations"][provider] = rec
        states = {r["state"] for r in manifest["operations"].values()}
        completed = {name for name, operation in manifest["operations"].items() if operation["state"] == "succeeded"}
        if set(manifest["required_engines"]) <= completed: manifest["state"] = "collected"
        elif "succeeded" in states or "partial" in states: manifest["state"] = "partial"
        else: manifest["state"] = next((state for state in ("unknown", "submitting", "submitted", "running", "failed") if state in states), "ready")
        manifest["events"].append({"at": now(), "state": rec["state"], "provider": provider, "actor": args.actor, "operation": rec})
        save_manifest(directory, manifest); write_json(under(directory, f"operations/{provider}.json"), rec)
    next_action = {"submitting": "record returned operation ID or mark unknown", "unknown": "reconcile provider inventory", "submitted": "collect this operation ID", "running": "collect this operation ID", "partial": "collect remaining operation IDs", "succeeded": "stage acceptance evidence", "failed": "pause provider admission and reconcile"}[rec["state"]]
    return {"item": key, "run_id": args.run_id, "provider": provider, "state": rec["state"], "operation_id": rec.get("operation_id"), "raw": rec.get("raw"), "next_action": next_action}


def resolved(root: Path, key: str) -> bool:
    directory = topic_dir(root, key)
    return index_statuses(root).get(key) == "resolved" and (directory / "DECISION.md").is_file() and (directory / "acceptance.json").is_file() and not validation_errors(root, key)


def index_statuses(root: Path) -> dict[str, str]:
    result = {}
    for line in (root / "research/CLAUDE.md").read_text().splitlines():
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) == 8 and ITEM_RE.fullmatch(cells[0]): result[cells[0]] = cells[-1]
    return result


def research_graph(root: Path) -> dict[str, set[str]]:
    keys = sorted(policy(root)["items"])
    texts = {key: "\n".join(coupling_lines(prompt_path(root, key).read_text())) for key in keys}
    owners = {key for key, text in texts.items() if re.search(r"(?m)^- owns:[ \t]*[^ \t\r\n]", text)}
    graph = {key: set() for key in keys}
    for key, text in texts.items():
        for line in text.splitlines():
            if line.startswith("- consumes:"):
                graph[key].update(x for x in re.findall(r"\bR\d\d\b", line) if x != key and x in graph)
            if key not in owners and line.startswith("- related"):
                graph[key].update(x for x in re.findall(r"\bR\d\d\b", line) if x != key and x in owners)
    return graph


def outside_fences(text: str) -> list[str]:
    lines = []; fence = None
    for line in text.splitlines():
        match = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if fence:
            if match and match[1][0] == fence[0] and len(match[1]) >= len(fence) and not match[2].strip(): fence = None
        elif match and not (match[1][0] == "`" and "`" in match[2]): fence = match[1]
        else: lines.append(line)
    return lines


def coupling_lines(text: str) -> list[str]:
    lines = outside_fences(text)
    if "## Couplings" not in lines: return []
    begin = lines.index("## Couplings") + 1
    end = next((i for i in range(begin, len(lines)) if lines[i].startswith("## ")), len(lines))
    return lines[begin:end]


def check_history(destination: Path, desired: bytes) -> None:
    if destination.name != "DECISION.md" or not destination.exists() or destination.read_bytes() == desired: return
    old = destination.read_bytes()
    text = desired.decode("utf-8")
    lines = outside_fences(text)
    if "## Supersedes" not in lines or not re.search(r"(?m)^#(?:##)? \d{4}-\d{2}-\d{2}(?:\s|$)", "\n".join(lines).split("## Supersedes", 1)[0]):
        raise RunnerError("decision revision requires a dated current entry and ## Supersedes history")
    if old not in desired.split(b"\n## Supersedes", 1)[-1]:
        raise RunnerError("decision revision must preserve prior DECISION.md bytes verbatim under ## Supersedes")

def research_prereqs(root: Path, key: str) -> set[str]:
    return research_graph(root)[key]


def queue(args: argparse.Namespace, root: Path) -> dict[str, Any]:
    if journal_path(root).exists():
        raise RunnerError("publication recovery is required before queue admission; run publication recover")
    errors = validation_errors(root)
    if errors: raise RunnerError("execution policy invalid: " + "; ".join(errors))
    p = policy(root); choices = []; graph = research_graph(root)
    paused: set[str] = set()
    for manifest_file in (root / "research" / "runs").glob("R??/*/manifest.json"):
        try:
            manifest = read_json(under(root, str(manifest_file.relative_to(root))))
            for record in manifest.get("operations", {}).values():
                if record.get("state") == "failed": paused.add(str(record.get("provider")))
        except RunnerError:
            raise RunnerError(f"unreadable run state blocks admission: {manifest_file}")
    statuses = index_statuses(root)
    for key, entry in p["items"].items():
        if statuses.get(key) == "dropped": continue
        if resolved(root, key): continue
        active = list((root / "research" / "runs" / key).glob("*/manifest.json"))
        if any(read_json(under(root, str(path.relative_to(root)))).get("state") not in {"failed", "published"} for path in active):
            continue
        research_after = graph[key]
        blocked = sorted(x for x in research_after if not resolved(root, x))
        if blocked or paused.intersection(entry.get("engines", [])): continue
        pp = prompt_path(root, key)
        owns = bool(re.search(r"(?m)^- owns:[ \t]*[^ \t\r\n]", "\n".join(coupling_lines(pp.read_text()))))
        descendants = {key}; previous = set()
        while descendants != previous:
            previous = set(descendants)
            descendants.update(candidate for candidate, deps in graph.items() if deps.intersection(previous))
        consumers = len(descendants) - 1
        choices.append({"item": key, "tier": entry.get("tier"), "research_after": sorted(research_after), "acceptance_after": entry.get("acceptance_after", []), "owner": owns, "unblocks": consumers, "priority": [0 if owns else 1, -consumers, key]})
    choices.sort(key=lambda x: x.pop("priority"))
    return {"ready": choices, "count": len(choices), "policy": "research/EXECUTION.json", "paused_providers": sorted(paused)}


def allowed_target(root: Path, key: str, target: str) -> Path:
    relative = safe_relative(target); topic = topic_dir(root, key).relative_to(root)
    allowed = {Path("research/CLAUDE.md"), Path("docs/port/PARAMETERS.md"), Path("docs/port/COMMONALITY.md"), topic / "DECISION.md", topic / "acceptance.json", topic / "audit-codex.md", topic / "audit-fable.md"}
    generated = relative.parent in {topic / "raw", topic / "evidence"} and bool(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*\.(?:md|log)", relative.name)) and relative.suffix == (".md" if relative.parent.name == "raw" else ".log")
    if relative not in allowed and not generated: raise UsageError(f"publication target is not controlled: {target}")
    return under(root, target)


def journal_path(root: Path) -> Path: return under(root, "research/runs/.publication-journal.json")


def publication_lock(root: Path) -> Path: return under(root, "research/runs/.publication.lock")


def require_recovered(root: Path) -> None:
    if journal_path(root).exists(): raise RunnerError("publication recovery is required; run publication recover")


def _recover_unlocked(root: Path) -> dict[str, Any]:
    journal = journal_path(root)
    if not journal.exists(): return {"recovered": False}
    data = read_json(journal)
    if not isinstance(data, dict) or set(data) != {"schema_version", "id", "item", "run_id", "created_at", "changes", "read_hashes"} or type(data["schema_version"]) is not int or data["schema_version"] != 1 or not isinstance(data["id"], str) or not data["id"]:
        raise RunnerError("invalid publication journal metadata")
    key = item(data.get("item", ""))
    load_manifest(root, key, data["run_id"])
    if not isinstance(data.get("changes"), list) or not data["changes"]: raise RunnerError("journal changes must be nonempty")
    targets = []
    prepared = []
    read_hashes = data.get("read_hashes")
    if not isinstance(read_hashes, dict): raise RunnerError("journal requires read_hashes")
    for change in data["changes"]:
        if not isinstance(change, dict) or set(change) != {"target", "expected_sha256", "desired_sha256", "desired"}:
            raise RunnerError("invalid journal change fields")
        destination = allowed_target(root, key, change["target"])
        if change["target"] in targets: raise RunnerError("journal contains duplicate targets")
        targets.append(change["target"])
        desired = base64.b64decode(change["desired"], validate=True)
        if digest_bytes(desired) != change["desired_sha256"]: raise RunnerError("journal desired bytes corrupted")
        current = sha(destination)
        if destination.parent.name in {"raw", "evidence"} and change["expected_sha256"] != "missing":
            raise RunnerError("journal cannot overwrite published raw or evidence")
        if current not in {change["expected_sha256"], change["desired_sha256"]}:
            raise RunnerError(f"recovery CAS refused intervening contents: {change['target']}")
        if destination.exists() and destination.is_symlink(): raise RunnerError(f"refuse symlink publication target: {destination}")
        check_history(destination, desired)
        prepared.append((destination, desired))
    desired_hashes = {change["target"]: change["desired_sha256"] for change in data["changes"]}
    for relative, expected in read_hashes.items():
        if sha(under(root, relative)) not in {expected, desired_hashes.get(relative)}:
            raise RunnerError(f"recovery stale input refused: {relative}")
    # Preflight the entire journal before writing any target.
    for destination, desired in prepared: atomic(destination, desired)
    finalize_publication(root, data)
    journal.unlink()
    return {"recovered": True, "mode": "rollforward", "transaction": data["id"]}


def finalize_publication(root: Path, transaction: dict[str, Any]) -> None:
    """Keep completed runs terminal when their accepted topic is later reopened."""
    key, run_id = transaction["item"], transaction["run_id"]
    directory, _ = load_manifest(root, key, run_id)
    with DirLock(directory / ".lock"):
        directory, manifest = load_manifest(root, key, run_id)
        receipt = {"transaction": transaction["id"], "decision_sha256": sha(topic_dir(root, key) / "DECISION.md"), "acceptance_sha256": sha(topic_dir(root, key) / "acceptance.json")}
        if manifest.get("publication") == receipt and manifest.get("state") == "published": return
        manifest["state"] = "published"
        manifest["publication"] = receipt
        manifest["events"].append({"at": now(), "state": "published", "publication": receipt})
        save_manifest(directory, manifest)


def recover(root: Path) -> dict[str, Any]:
    """Recover only while holding the same single-writer lock as publication."""
    with DirLock(publication_lock(root)):
        return _recover_unlocked(root)


def publish(args: argparse.Namespace, root: Path) -> dict[str, Any]:
    with DirLock(publication_lock(root)):
        require_recovered(root)
        return _publish_unlocked(args, root)


def _publish_unlocked(args: argparse.Namespace, root: Path) -> dict[str, Any]:
    if args.manifest == "-":
        try: manifest = json.load(sys.stdin)
        except json.JSONDecodeError as exc: raise UsageError(f"invalid publication manifest on stdin: {exc}") from exc
    else:
        manifest = read_json(Path(args.manifest).resolve())
    key = item(manifest.get("item", "")); changes = manifest.get("changes")
    if not isinstance(changes, list) or not changes: raise UsageError("publication manifest needs nonempty changes")
    if "dependency_hashes" not in manifest: raise UsageError("publication manifest needs dependency_hashes")
    if not isinstance(manifest.get("run_id"), str): raise UsageError("publication manifest needs run_id")
    _, run_manifest = load_manifest(root, key, manifest["run_id"])
    if run_manifest.get("state") == "published": raise RunnerError("published run is immutable; prepare a new run for another publication")
    stale = freshness_errors(root, key, run_manifest)
    if stale: raise RunnerError("; ".join(stale))
    entry = policy(root)["items"].get(key, {})
    unresolved = [x for x in entry.get("acceptance_after", []) if not resolved(root, x)]
    if unresolved: raise RunnerError(f"unresolved acceptance prerequisites for {key}: {', '.join(unresolved)}")
    dependency_hashes = manifest.get("dependency_hashes", {})
    if not isinstance(dependency_hashes, dict): raise UsageError("dependency_hashes must be an object")
    for relative, expected in dependency_hashes.items():
        if not isinstance(relative, str) or not isinstance(expected, str) or sha(under(root, relative)) != expected:
            raise RunnerError(f"stale dependency hash: {relative}")
    errors = validation_errors(root)
    if errors: raise RunnerError("refuse publication before validation: " + "; ".join(errors))
    staged = Path(args.staged_dir).resolve()
    if not staged.is_dir(): raise UsageError("--staged-dir must be a directory")
    journal_changes = []
    targets = [change.get("target") for change in changes if isinstance(change, dict)]
    if len(targets) != len(changes) or len(targets) != len(set(targets)):
        raise UsageError("publication manifest has duplicate or invalid targets")
    for change in changes:
        if set(change) != {"target", "expected_sha256", "staged"}: raise UsageError("each change needs exactly target, expected_sha256, staged")
        dest = allowed_target(root, key, change["target"])
        if dest.exists() and dest.is_symlink(): raise RunnerError(f"refuse symlink publication target: {dest}")
        topic = topic_dir(root, key).relative_to(root)
        if tuple(safe_relative(change["target"]).parts[:len(topic.parts) + 1]) in {topic.parts + ("raw",), topic.parts + ("evidence",)} and dest.exists():
            raise RunnerError(f"never overwrite published raw or evidence: {change['target']}")
        if sha(dest) != change["expected_sha256"]: raise RunnerError(f"CAS failed for {change['target']}")
        source = under(staged, change["staged"])
        if not source.is_file() or source.is_symlink(): raise RunnerError("staged source must be a regular file beneath --staged-dir")
        desired = source.read_bytes()
        check_history(dest, desired)
        journal_changes.append({"target": change["target"], "expected_sha256": change["expected_sha256"], "desired_sha256": digest_bytes(desired), "desired": base64.b64encode(desired).decode()})
    # Validate a complete staged copy before mutating live files.
    with tempfile.TemporaryDirectory(prefix="research-publication-") as tmp:
        candidate = Path(tmp) / "root"; shutil.copytree(root, candidate, symlinks=True, ignore=shutil.ignore_patterns("runs"))
        for change in journal_changes: atomic(under(candidate, change["target"]), base64.b64decode(change["desired"]))
        errors = validation_errors(candidate, key)
        if index_statuses(candidate).get(key) != "resolved": errors.append("published item must be resolved in staged index")
        for accepted, status in index_statuses(candidate).items():
            if status == "resolved" and accepted != key: errors.extend(validation_errors(candidate, accepted))
        if errors: raise RunnerError("staged publication invalid: " + "; ".join(errors))
        checker = under(candidate, "scripts/check-research-tree.sh")
        if not checker.is_file(): raise RunnerError("missing required scripts/check-research-tree.sh")
        environment = os.environ.copy()
        environment["PATH"] = str(Path(sys.executable).parent) + os.pathsep + environment.get("PATH", "")
        checked = subprocess.run(["/bin/bash", str(checker), "--require-owner-review", str(candidate)], text=True, capture_output=True, env=environment)
        if checked.returncode: raise RunnerError("staged structural validation failed: " + checked.stdout.strip() + " " + checked.stderr.strip())
    # Recovery also guards inputs that publication did not overwrite.
    read_paths = {"research/CLAUDE.md", "research/EXECUTION.json", "docs/port/PARAMETERS.md", str(prompt_path(root, key).relative_to(root))}
    for prerequisite in research_prereqs(root, key) | set(entry.get("acceptance_after", [])):
        read_paths.update(str((topic_dir(root, prerequisite) / name).relative_to(root)) for name in ("DECISION.md", "acceptance.json"))
    read_hashes = {relative: sha(under(root, relative)) for relative in read_paths}
    transaction = {"schema_version": 1, "id": uuid.uuid4().hex, "item": key, "run_id": manifest["run_id"], "created_at": now(), "changes": journal_changes, "read_hashes": read_hashes}
    # Repeat CAS for intervening manual edits; cooperating publishers hold this lock.
    for change in journal_changes:
        if sha(under(root, change["target"])) != change["expected_sha256"]:
            raise RunnerError(f"CAS failed under writer lock for {change['target']}")
    for relative, expected in dependency_hashes.items():
        if sha(under(root, relative)) != expected:
            raise RunnerError(f"stale dependency hash under writer lock: {relative}")
    stale = freshness_errors(root, key, run_manifest)
    if stale: raise RunnerError("; ".join(stale))
    write_json(journal_path(root), transaction)
    for index, change in enumerate(journal_changes, start=1):
        atomic(under(root, change["target"]), base64.b64decode(change["desired"]))
        if os.environ.get("RESEARCH_RUNNER_FAIL_AFTER") == str(index): raise RunnerError("injected publication interruption; rerun recover")
    finalize_publication(root, transaction)
    journal_path(root).unlink()
    return {"published": True, "transaction": transaction["id"], "item": key, "changes": [c["target"] for c in journal_changes]}


def parser() -> argparse.ArgumentParser:
    p = Parser(description=__doc__, allow_abbrev=False)
    p.add_argument("--root")
    add_common_arguments(p, VERSION)
    sub = p.add_subparsers(dest="command", required=True)
    # Noun groups are the public interface: each run command only records
    # local durable state; it never contacts a provider.
    run = sub.add_parser("run", allow_abbrev=False, help="prepare and reconcile one durable run")
    run_sub = run.add_subparsers(dest="run_action", required=True)
    def run_common(name: str, provider: bool = False):
        x = run_sub.add_parser(name, allow_abbrev=False); x.add_argument("item"); x.add_argument("--run-id", required=True); x.add_argument("--actor", default="unknown"); x.add_argument("--model", default="unknown")
        if provider: x.add_argument("--provider", required=True)
        return x
    x = run_sub.add_parser("prepare", allow_abbrev=False); x.add_argument("item"); x.add_argument("--run-id"); x.add_argument("--actor", required=True); x.add_argument("--model", required=True); x.add_argument("--authorization-ref", required=True); x.add_argument("--budget", required=True)
    x = run_common("intent", True); x.add_argument("--request-id")
    x = run_common("submitted", True); x.add_argument("--operation-id", required=True); x.add_argument("--actual-provider"); x.add_argument("--actual-model")
    x = run_common("unknown", True); x.add_argument("--reason", required=True)
    x = run_common("collect", True); x.add_argument("--state", required=True); x.add_argument("--reason", default=""); x.add_argument("--raw-file")
    x = run_common("status"); x.add_argument("--provider")
    que = sub.add_parser("queue", allow_abbrev=False, help="list research-ready items"); que.add_subparsers(dest="queue_action", required=True).add_parser("list", allow_abbrev=False)
    pub = sub.add_parser("publication", allow_abbrev=False, help="apply or recover a controlled publication")
    pub_sub = pub.add_subparsers(dest="publication_action", required=True)
    x = pub_sub.add_parser("apply", allow_abbrev=False); x.add_argument("--file", "--manifest", dest="manifest", required=True, help="JSON file, or - for stdin"); x.add_argument("--staged-dir", required=True)
    pub_sub.add_parser("recover", allow_abbrev=False)
    return p


def main(argv: list[str] | None = None) -> int:
    raw_argv = list(sys.argv[1:] if argv is None else argv)
    try:
        args = parse_args(parser(), raw_argv)
        if args.command == "run": args.command = args.run_action
        elif args.command == "queue":
            if getattr(args, "queue_action", None) == "list": args.command = "queue"
        elif args.command == "publication": args.command = "publish" if args.publication_action == "apply" else "recover"
        root = root_from(args.root)
        if args.command in {"prepare", "intent", "queue"}:
            with DirLock(publication_lock(root)):
                require_recovered(root)
                if args.command == "prepare": result = prepare(args, root)
                elif args.command == "intent": result = update_operation(args, root, args.command)
                else: result = queue(args, root)
        elif args.command in {"intent", "submitted", "unknown", "collect"}: result = update_operation(args, root, args.command)
        elif args.command == "status":
            directory, state = load_manifest(root, item(args.item), args.run_id); result = state if not args.provider else state["operations"].get(args.provider, {})
        elif args.command == "recover": result = recover(root)
        else: result = publish(args, root)
        diagnostic(args, "local offline runner operation completed", level=1)
        envelope = {"ok": True, "result": result}
        if args.json: print(json.dumps(envelope, sort_keys=True))
        else: print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (RunnerError, UsageError, OSError, ValueError, TypeError, KeyError, AttributeError) as exc:
        return emit_error(exc, raw_argv, code="refused")
    except KeyboardInterrupt:
        return 130

if __name__ == "__main__": raise SystemExit(main())
