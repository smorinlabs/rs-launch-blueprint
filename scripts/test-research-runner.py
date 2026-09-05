#!/usr/bin/env python3
"""Offline integration tests with the real validator and synthetic evidence.

Schema-valid test records are not claims that research or paid calls occurred.
"""
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RUNNER = Path(os.environ.get("RESEARCH_RUNNER_TEST_SCRIPT", str(REPO / "scripts/research_runner.py")))
spec = importlib.util.spec_from_file_location("validator", REPO / "scripts/research_validation.py")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else "missing"


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def jswrite(path, obj):
    write(path, json.dumps(obj))


def run(root, *args, ok=True, contains=None, env=None):
    if args[0] in {"prepare", "intent", "submitted", "unknown", "collect", "status"}: args = ("run", args[0], *args[1:])
    elif args[0] == "publish": args = ("publication", "apply", *args[1:])
    elif args[0] == "recover": args = ("publication", "recover", *args[1:])
    environment = os.environ.copy(); environment.update(env or {})
    p = subprocess.run([sys.executable, str(RUNNER), "--root", str(root), "--json", *args], text=True, capture_output=True, env=environment)
    assert (p.returncode == 0 if ok else p.returncode in {1, 2}), (p.returncode, p.stdout, p.stderr)
    assert not (p.stderr if ok else p.stdout), (p.stdout, p.stderr)
    data = json.loads(p.stdout if ok else p.stderr)
    assert (data.get("ok") is True if ok else isinstance(data.get("error"), dict)), data
    if contains: assert contains in json.dumps(data), data
    return data["result"] if ok else data


def make_fixture(root):
    for name in ("research_validation.py", "research_cli.py", "check-research-tree.sh"):
        write(root / "scripts" / name, (REPO / "scripts" / name).read_text())
    core = REPO / "scripts/check-research-tree-core.sh"
    if core.exists(): write(root / "scripts" / core.name, core.read_text())
    (root / "docs/planning/p02").mkdir(parents=True)
    write(root / "research/RUNBOOK.md", "Synthetic fixture.\n")
    write(root / "docs/port/COMMONALITY.md", "| ID | Feature | Area | Origin | Verdict | Item | Notes |\n|---|---|---|---|---|---|---|\n" + "".join(f"| F00{n} | fixture | cli-framework-ux | different | DIVERGENT | R0{n} | fixture |\n" for n in range(1, 4)))
    write(root / "docs/port/OWNER-REVIEW.md", "| item | disposition | rationale | date |\n|---|---|---|---|\n" + "".join(f"| R0{n} | accept | fixture | 2026-09-04 |\n" for n in range(1, 4)))
    write(root / "docs/port/PARAMETERS.md", "| param | kind | owner | value | description |\n|---|---|---|---|---|\n| thing | researched | R01 | v1 | fixture |\n| edition | fixed | owner | 2024 | fixture |\n" + "".join(f"| {name} | fixed | owner | fixture | fixture |\n" for name in ("msrv-policy", "rust-edition", "target-os-matrix", "license")))
    index = "| id | slug | kind | origin | verdict | owns | prompt | status |\n|---|---|---|---|---|---|---|---|\n"
    items = {}
    for key, owns, consumes, after in (("R01", "thing", "", []), ("R02", "", "R01: thing; owner: edition", []), ("R03", "", "", ["R01"])):
        slug = key.lower()
        index += f"| {key} | {slug} | pattern | different | DIVERGENT | {owns or '—'} | [prompt](topics/{key[1:]}-{slug}/prompts/{slug}.prompt.md) | open |\n"
        engines = ["codex", "opus", "doxa"] if key == "R01" else ["codex", "opus"]
        items[key] = {"tier": "focused", "engines": engines, "evidence_checks": [], "acceptance_after": after}
        text = f"## Objective\nfixture\n\n## Context\nfixture\n\n## Out of scope\nfixture\n\n## Couplings\n- id: {key}\n- owns: {owns}\n- consumes: {consumes}\n- effort: focused\n- engines: {', '.join(engines)}\n- evidence-checks:\n- acceptance-after: {', '.join(after)}\n\n## Questions\nfixture\n\n## Required evidence\nfixture\n\n## Answer template\nfixture\n\n## Constraints\nfixture\n"
        write(root / f"research/topics/{key[1:]}-{slug}/prompts/{slug}.prompt.md", text)
    write(root / "research/CLAUDE.md", index)
    jswrite(root / "research/EXECUTION.json", {"schema_version": 1, "approved_on": "2026-09-04", "pilot": "R01", "items": items})
    assert validator.validate_execution_policy(root) == []


def topic(root, key):
    return next((root / "research/topics").glob(key[1:] + "-*"))


def accept_fixture(root, key, kind="pattern", consumed=None, fixed=None, prereqs=None, revision=False):
    """Build a complete, real-validator GREEN bundle in a temporary tree."""
    directory = topic(root, key)
    prompt = next((directory / "prompts").glob("*.prompt.md"))
    policy = json.loads((root / "research/EXECUTION.json").read_text())["items"][key]
    decision = directory / "DECISION.md"
    history = decision.read_text() if revision else ""
    registry = validator._parse_parameters(root, [])
    owned = [name for name, row in registry.items() if row.get("owner") == key]
    assumptions = {name: row["value"] for name, row in registry.items() if row.get("kind") == "fixed"}
    assumptions.update(consumed or {})
    parameters_text = "\n".join([f"- owns {name} = {registry[name]['value']}" for name in owned] + [f"- assumes {name} = {value}" for name, value in assumptions.items()]) or "Fixture values."
    current = f"## Decision\nSynthetic fixture only.\n\n### Principles and implementation\nFixture integrity.\nre-verify: fixture changes\n\n## Parameters\n{parameters_text}\n\n## Empirical check\nSynthetic log.\n\n## Engines\nSynthetic reports agree.\n"
    write(decision, "# 2026-09-04\n\n" + current + "\n## Supersedes\n" + history if revision else current)
    identity = lambda actor, family: {"actor": actor, "model": "fixture-model", "family": family}
    artifact = lambda path, who: {"path": str(path.relative_to(root)), "sha256": digest(path), "identity": who}
    reports = []
    for engine in policy["engines"]:
        raw = directory / f"raw/{engine}-{'revision' if revision else 'fixture'}.md"
        fields = validator.CRATE_FIELDS if kind == "crate" else validator.PATTERN_FIELDS
        write(raw, "\n\n".join(f"### {field}\nSynthetic fixture content." for field in fields))
        reports.append(dict(engine=engine, **artifact(raw, identity(f"{key}-{engine}-producer", {"codex": "openai", "opus": "anthropic", "doxa": "mixed"}[engine]))))
    audits = []; executor = None
    for audit_kind, name, family in (("empirical", "codex", "openai"), ("judgment", "fable", "anthropic")):
        who = identity(f"{key}-{audit_kind}-auditor", family)
        if audit_kind == "empirical": executor = who
        path = directory / f"audit-{name}.md"
        write(path, f"decision-sha256: {digest(decision)}\nactor: {who['actor']}\nmodel: {who['model']}\nfamily: {family}\nverdict: approve\nunresolved-findings: none\n\nSynthetic fixture analysis; no real research performed.\n")
        audits.append(dict(kind=audit_kind, **artifact(path, who), decision_sha256=digest(decision), verdict="approve", unresolved_findings=[]))
    log = directory / ("evidence/revision.log" if revision else "evidence/fixture.log"); write(log, "Synthetic fixture output.\n")
    acceptance = {"item": key, "schema_version": 1, "decision_sha256": digest(decision), "prompt_sha256": digest(prompt), "policy_snapshot": policy, "engine_reports": reports, "evidence_checks": [], "synthesis": identity(f"{key}-synthesizer", "anthropic"), "audits": audits, "empirical": {"argv": ["fixture-command"], "cwd": "synthetic-fixture", "toolchain": "synthetic", "output_log": str(log.relative_to(root)), "output_sha256": digest(log), "exit_code": 0, "executed_by": executor}, "parameters": {"consumed": consumed or {}, "fixed": fixed or {}}, "prerequisites": {"research": prereqs or {}, "acceptance_after": {p: digest(topic(root, p) / "DECISION.md") for p in policy["acceptance_after"]}}, "reverify": "fixture changes", "engines": "synthetic reports", "principles": "fixture integrity"}
    jswrite(directory / "acceptance.json", acceptance)
    acceptance["parameters"]["fixed"] = {name: row["value"] for name, row in registry.items() if row.get("kind") == "fixed"}
    jswrite(directory / "acceptance.json", acceptance)
    index = root / "research/CLAUDE.md"
    write(index, "\n".join(line.replace("| open |", "| resolved |") if line.startswith(f"| {key} |") else line for line in index.read_text().splitlines()) + "\n")
    assert validator.validate_topic(root, key) == [], validator.validate_topic(root, key)


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve(); make_fixture(self.root)

    def prepare(self, key="R01", name="run"):
        return run(self.root, "prepare", key, "--run-id", name, "--actor", "fixture", "--model", "fixture-model", "--authorization-ref", "offline-test", "--budget", "0")

    def op(self, action, *extra, key="R01", name="run", **kw):
        return run(self.root, action, key, "--run-id", name, "--provider", "codex", *extra, **kw)

    def publication(self):
        self.prepare(); staged = self.root / "staged"
        shutil.copytree(self.root, staged, ignore=shutil.ignore_patterns("staged", "runs", "__pycache__"))
        accept_fixture(staged, "R01")
        return self.make_manifest(staged)

    def make_manifest(self, staged, key="R01"):
        changes = []
        for path in sorted(staged.rglob("*")):
            if path.is_file():
                relative = str(path.relative_to(staged))
                if digest(path) != digest(self.root / relative): changes.append({"target": relative, "expected_sha256": digest(self.root / relative), "staged": relative})
        manifest = self.root / "publication.json"
        jswrite(manifest, {"item": key, "run_id": "run", "dependency_hashes": {}, "changes": changes})
        return manifest, staged

    def publish(self, manifest, staged, **kw):
        return run(self.root, "publish", "--file", str(manifest), "--staged-dir", str(staged), **kw)

    def tree(self):
        return subprocess.run([sys.executable, str(self.root / "scripts/research_validation.py"), "--json", "tree", "--root", str(self.root)], text=True, capture_output=True)

    def test_first_acceptance_uses_real_validator_and_full_tree(self):
        manifest, staged = self.publication()
        self.assertFalse((topic(self.root, "R01") / "DECISION.md").exists())
        self.publish(manifest, staged)
        self.assertEqual([], validator.validate_topic(self.root, "R01"))
        result = self.tree(); self.assertEqual(0, result.returncode, result.stderr)

    def test_published_run_does_not_block_reopened_item(self):
        manifest, staged = self.publication()
        self.assertNotIn("R01", {row["item"] for row in run(self.root, "queue", "list")["ready"]})
        self.publish(manifest, staged)
        state = run(self.root, "status", "R01", "--run-id", "run")
        self.assertEqual("published", state["state"])
        self.assertEqual(digest(topic(self.root, "R01") / "acceptance.json"), state["publication"]["acceptance_sha256"])
        index = self.root / "research/CLAUDE.md"
        write(index, "\n".join(line.replace("| resolved |", "| in-progress |") if line.startswith("| R01 |") else line for line in index.read_text().splitlines()) + "\n")
        self.assertIn("R01", {row["item"] for row in run(self.root, "queue", "list")["ready"]})
        self.op("intent", ok=False, contains="published run is immutable")
        self.publish(manifest, staged, ok=False, contains="published run is immutable")
        self.prepare(name="new-research")
        self.assertNotIn("R01", {row["item"] for row in run(self.root, "queue", "list")["ready"]})

    def test_recovery_finalizes_receipt_after_all_targets_written(self):
        manifest, staged = self.publication()
        count = len(json.loads(manifest.read_text())["changes"])
        self.publish(manifest, staged, ok=False, env={"RESEARCH_RUNNER_FAIL_AFTER": str(count)})
        self.assertEqual("ready", run(self.root, "status", "R01", "--run-id", "run")["state"])
        run(self.root, "recover")
        state = run(self.root, "status", "R01", "--run-id", "run")
        self.assertEqual("published", state["state"])
        self.assertFalse(run(self.root, "recover")["recovered"])
        self.assertEqual(state, run(self.root, "status", "R01", "--run-id", "run"))

    def test_invalid_candidate_cannot_publish_from_open(self):
        manifest, staged = self.publication()
        write(topic(staged, "R01") / "audit-codex.md", "verdict: reject\n")
        self.publish(manifest, staged, ok=False, contains="staged publication invalid")
        self.assertFalse((topic(self.root, "R01") / "DECISION.md").exists())

    def test_unknown_reconciliation_and_raw_preservation(self):
        self.prepare(); self.op("intent"); self.op("unknown", "--reason", "timeout")
        self.op("intent", ok=False, contains="duplicate submission")
        self.op("collect", "--state", "running", ok=False, contains="unknown")
        self.op("submitted", "--operation-id", "reconciled-id")
        write(self.root / "research/runs/R01/run/inputs/result.md", "original bytes")
        result = self.op("collect", "--state", "succeeded", "--raw-file", "inputs/result.md")
        self.assertEqual("reconciled-id", result["operation_id"])
        self.assertEqual("original bytes", (self.root / result["raw"]).read_text())

    def test_mutated_saved_snapshots_refused(self):
        self.prepare()
        for name in ("prompt.md", "prerequisites.json", "parameters.json", "EXECUTION.json", "CLAUDE.md", "PARAMETERS.md"):
            path = self.root / "research/runs/R01/run/inputs" / name; old = path.read_bytes()
            path.write_bytes(old + b" "); self.op("intent", ok=False, contains="modified immutable snapshot"); path.write_bytes(old)
        self.op("intent")

    def test_parameter_and_prerequisite_freshness_discriminate(self):
        accept_fixture(self.root, "R01"); self.prepare("R02"); self.op("intent", key="R02"); self.prepare("R02", "stale")
        for path, replacement, expected in ((self.root / "docs/port/PARAMETERS.md", "v1", "stale input snapshot"), (self.root / "docs/port/PARAMETERS.md", "2024", "stale input snapshot"), (topic(self.root, "R01") / "DECISION.md", "Synthetic", "stale prerequisite snapshot")):
            old = path.read_text(); write(path, old.replace(replacement, replacement + "-changed"))
            self.op("intent", key="R02", name="stale", ok=False, contains=expected); write(path, old)
        self.op("intent", key="R02", name="stale")

    def test_queue_research_and_acceptance_dependencies_differ(self):
        self.assertEqual({"R01", "R03"}, {row["item"] for row in run(self.root, "queue", "list")["ready"]})
        accept_fixture(self.root, "R01")
        self.assertIn("R02", {row["item"] for row in run(self.root, "queue", "list")["ready"]})

    def test_writer_lock_blocks_admission_and_publication(self):
        manifest, staged = self.publication(); lock = self.root / "research/runs/.publication.lock"; lock.mkdir()
        run(self.root, "queue", "list", ok=False, contains="active lock"); self.op("intent", ok=False, contains="active lock")
        reader = self.tree()
        self.assertEqual(1, reader.returncode); self.assertEqual("", reader.stdout)
        self.assertIn("publication lock", reader.stderr)
        legacy_reader = subprocess.run(["/bin/bash", str(self.root / "scripts/check-research-tree.sh"), "--require-owner-review", str(self.root)], text=True, capture_output=True)
        self.assertEqual(1, legacy_reader.returncode); self.assertIn("publication lock", legacy_reader.stdout + legacy_reader.stderr)
        self.publish(manifest, staged, ok=False, contains="active lock"); lock.rmdir(); self.publish(manifest, staged)

    def test_crash_recovery_blocks_readers_and_rolls_forward(self):
        manifest, staged = self.publication()
        self.publish(manifest, staged, ok=False, contains="injected", env={"RESEARCH_RUNNER_FAIL_AFTER": "1"})
        run(self.root, "queue", "list", ok=False, contains="recovery"); self.op("intent", ok=False, contains="recovery")
        reader = self.tree(); self.assertEqual(1, reader.returncode); self.assertIn("recovery", reader.stderr); self.assertEqual("", reader.stdout)
        run(self.root, "recover")
        self.assertEqual([], validator.validate_topic(self.root, "R01"))
        state = run(self.root, "status", "R01", "--run-id", "run")
        self.assertEqual("published", state["state"])
        self.assertEqual(digest(topic(self.root, "R01") / "DECISION.md"), state["publication"]["decision_sha256"])
        for change in json.loads(manifest.read_text())["changes"]: self.assertEqual((staged / change["staged"]).read_bytes(), (self.root / change["target"]).read_bytes())

    def interrupted(self):
        manifest, staged = self.publication(); self.publish(manifest, staged, ok=False, env={"RESEARCH_RUNNER_FAIL_AFTER": "1"})
        path = self.root / "research/runs/.publication-journal.json"
        return path, json.loads(path.read_text())

    def test_recovery_preflights_all_cas_before_any_write(self):
        _, journal = self.interrupted(); pending = self.root / journal["changes"][1]["target"]
        self.assertFalse(pending.exists()); last = self.root / journal["changes"][-1]["target"]; write(last, "intervening owner work")
        run(self.root, "recover", ok=False, contains="recovery CAS refused")
        self.assertFalse(pending.exists(), "earlier write happened before later CAS refusal"); self.assertEqual("intervening owner work", last.read_text())

    def test_duplicate_alias_and_escape_targets_refused(self):
        manifest, staged = self.publication(); original = json.loads(manifest.read_text())
        for target in ("research/./CLAUDE.md", "../outside", "scripts/research_validation.py", "research/topics/01-r01/raw/../../evil.md"):
            bad = json.loads(json.dumps(original)); bad["changes"].append({"target": target, "staged": "research/CLAUDE.md", "expected_sha256": "missing"}); jswrite(manifest, bad)
            self.publish(manifest, staged, ok=False)
        duplicate = json.loads(json.dumps(original)); duplicate["changes"].append(duplicate["changes"][0]); jswrite(manifest, duplicate)
        self.publish(manifest, staged, ok=False, contains="duplicate")

    def test_symlink_run_and_raw_escape_refused(self):
        outside = self.root / "outside"; outside.mkdir(); (self.root / "research/runs").symlink_to(outside, target_is_directory=True)
        run(self.root, "prepare", "R01", "--actor", "a", "--model", "m", "--authorization-ref", "offline", "--budget", "0", ok=False, contains="symlink")
        self.assertEqual([], list(outside.iterdir())); (self.root / "research/runs").unlink()
        self.prepare(); self.op("intent"); self.op("submitted", "--operation-id", "id")
        (self.root / "research/runs/R01/run/inputs/link").symlink_to("/etc/hosts")
        self.op("collect", "--state", "succeeded", "--raw-file", "inputs/link", ok=False, contains="symlink")

    def test_journal_target_escape_refused_before_writes(self):
        path, journal = self.interrupted(); pending = self.root / journal["changes"][1]["target"]
        journal["changes"][-1]["target"] = "../outside"; jswrite(path, journal)
        run(self.root, "recover", ok=False, contains="unsafe"); self.assertFalse(pending.exists())

    def test_publication_and_recovery_refuse_changed_inputs(self):
        manifest, staged = self.publication(); registry = self.root / "docs/port/PARAMETERS.md"; old = registry.read_text()
        write(registry, old.replace("2024", "2025"))
        self.publish(manifest, staged, ok=False, contains="stale input snapshot")
        write(registry, old)
        self.publish(manifest, staged, ok=False, env={"RESEARCH_RUNNER_FAIL_AFTER": "1"})
        write(registry, old.replace("2024", "2025"))
        run(self.root, "recover", ok=False, contains="recovery stale input refused")
        write(registry, old); run(self.root, "recover")

    def test_partial_and_failed_operation_state_survives_mirror_loss(self):
        self.prepare(); self.op("intent"); self.op("submitted", "--operation-id", "id")
        self.op("collect", "--state", "succeeded")
        state = run(self.root, "status", "R01", "--run-id", "run")
        self.assertEqual("partial", state["state"], "one of three engines is not a collected run")
        self.op("collect", "--state", "failed", "--reason", "provider outage")
        (self.root / "research/runs/R01/run/operations/codex.json").unlink()
        queue = run(self.root, "queue", "list")
        self.assertEqual(["codex"], queue["paused_providers"])
        state = run(self.root, "status", "R01", "--run-id", "run")
        self.assertEqual("succeeded", state["events"][-2]["operation"]["state"])

    def test_full_production_tree_r38_first_acceptance(self):
        production = self.root / "production"
        shutil.copytree(REPO, production, ignore=shutil.ignore_patterns(".git", "runs", "__pycache__"))
        self.root = production; self.prepare("R38")
        staged = self.root / "staged"
        shutil.copytree(self.root, staged, ignore=shutil.ignore_patterns("staged", "runs", "__pycache__"))
        registry = staged / "docs/port/PARAMETERS.md"
        write(registry, "\n".join(line.replace("| — |", "| fixture-convention |") if line.startswith("| commit-message-convention |") else line for line in registry.read_text().splitlines()) + "\n")
        accept_fixture(staged, "R38", kind="crate")
        manifest, staged = self.make_manifest(staged, "R38")
        self.publish(manifest, staged)
        checked = subprocess.run(["/bin/bash", str(self.root / "scripts/check-research-tree.sh"), "--require-owner-review", str(self.root)], capture_output=True, text=True)
        self.assertEqual(0, checked.returncode, checked.stdout + checked.stderr)
        self.assertIn("OK: research tree structure valid", checked.stdout)

    def test_corrupt_ledger_and_missing_checker_fail_closed(self):
        manifest, staged = self.publication()
        write(staged / "docs/port/COMMONALITY.md", "broken ledger\n")
        manifest, staged = self.make_manifest(staged)
        self.publish(manifest, staged, ok=False, contains="staged structural validation failed")
        write(staged / "docs/port/COMMONALITY.md", (self.root / "docs/port/COMMONALITY.md").read_text())
        manifest, staged = self.make_manifest(staged)
        (self.root / "scripts/check-research-tree.sh").unlink()
        self.publish(manifest, staged, ok=False, contains="missing required scripts/check-research-tree.sh")

    def test_revision_preserves_history_and_reopens_stale_consumer(self):
        accept_fixture(self.root, "R01")
        accept_fixture(self.root, "R02", consumed={"thing": "v1"}, prereqs={"R01": digest(topic(self.root, "R01") / "DECISION.md")})
        old = (topic(self.root, "R01") / "DECISION.md").read_bytes()
        self.prepare(); staged = self.root / "staged"
        shutil.copytree(self.root, staged, ignore=shutil.ignore_patterns("staged", "runs", "__pycache__"))
        accept_fixture(staged, "R01", revision=True)
        manifest, staged = self.make_manifest(staged)
        self.publish(manifest, staged, ok=False, contains="R02 prerequisites.research.R01")
        index = staged / "research/CLAUDE.md"
        write(index, "\n".join(line.replace("| resolved |", "| in-progress |") if line.startswith("| R02 |") else line for line in index.read_text().splitlines()) + "\n")
        manifest, staged = self.make_manifest(staged)
        decision = topic(staged, "R01") / "DECISION.md"; good = decision.read_bytes()
        acceptance_path = topic(staged, "R01") / "acceptance.json"
        old_acceptance = acceptance_path.read_bytes()
        audits = {path: path.read_bytes() for path in topic(staged, "R01").glob("audit-*.md")}
        decision.write_bytes(good.split(b"\n## Supersedes", 1)[0])
        # Keep the revised bundle otherwise valid: a hash mismatch must not be
        # the reason this history-deleting publication is refused.
        acceptance = json.loads(old_acceptance)
        previous_hash = acceptance["decision_sha256"]; acceptance["decision_sha256"] = digest(decision)
        for audit in acceptance["audits"]:
            path = staged / audit["path"]
            write(path, path.read_text().replace(previous_hash, digest(decision)))
            audit["decision_sha256"] = digest(decision); audit["sha256"] = digest(path)
        jswrite(acceptance_path, acceptance)
        self.assertEqual([], validator.validate_topic(staged, "R01"))
        self.publish(manifest, staged, ok=False, contains="decision revision requires")
        decision.write_bytes(good); acceptance_path.write_bytes(old_acceptance)
        for path, data in audits.items(): path.write_bytes(data)
        self.publish(manifest, staged)
        self.assertIn(old, (topic(self.root, "R01") / "DECISION.md").read_bytes())
        self.assertIn("| in-progress |", (self.root / "research/CLAUDE.md").read_text())


if __name__ == "__main__": unittest.main(verbosity=2)
