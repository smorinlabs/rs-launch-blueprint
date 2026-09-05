#!/usr/bin/env python3
"""Offline tests for packaging a completed run directory into a publication.

The fixtures below are shape-valid synthetic records. They prove the packaging
tool assembles the acceptance bundle the validator demands; they are not a
claim that any research, audit, or paid provider call actually happened.
"""
import hashlib
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PACKAGER = REPO / "scripts/research_package.py"
RUNNER = REPO / "scripts/research_runner.py"
IGNORE = shutil.ignore_patterns(".git", "runs", "__pycache__", ".superpowers")
CONVENTION = "feat, fix, docs, chore; header 72; body 100; footer 100"


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load("validator", REPO / "scripts/research_validation.py")
# accept_fixture builds a complete GREEN bundle for a prerequisite topic.
fixtures = load("runner_fixtures", REPO / "scripts/test-research-runner.py")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else "missing"


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path


def answer(kind):
    fields = validator.CRATE_FIELDS if kind == "crate" else validator.PATTERN_FIELDS
    return "\n\n".join("### %s\nSynthetic fixture content." % field for field in fields) + "\n"


def registry_value(root, param):
    return validator._parse_parameters(root, [])[param]["value"]


def set_registry_value(root, param, value):
    path = root / "docs/port/PARAMETERS.md"
    lines = []
    for line in path.read_text().splitlines():
        if line.startswith("| %s |" % param):
            cells = line.split("|")
            cells[4] = " %s " % value
            line = "|".join(cells)
        lines.append(line)
    write(path, "\n".join(lines) + "\n")


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.work = Path(self.tmp.name).resolve()
        self.root = self.work / "root"
        shutil.copytree(REPO, self.root, ignore=IGNORE)
        self.staged_count = 0
        self.run_id = "package-fixture"
        self.prepare("R38")
        self.write_run("R38", "crate", ["codex", "opus", "doxa"],
                       owns={"commit-message-convention": CONVENTION})

    # ---- process helpers -------------------------------------------------

    def cli(self, script, *args, expect_ok=True, code="refused"):
        """A refusal exits 1, a usage error exits 2; both keep stdout empty."""
        result = subprocess.run([sys.executable, str(script), "--root", str(self.root), "--json", *args],
                                text=True, capture_output=True)
        if expect_ok:
            self.assertEqual(0, result.returncode, result.stdout + result.stderr)
            self.assertEqual("", result.stderr, result.stderr)
            return json.loads(result.stdout)
        self.assertEqual({"refused": 1, "usage": 2}[code], result.returncode, result.stdout + result.stderr)
        self.assertEqual("", result.stdout, result.stdout)
        failure = json.loads(result.stderr)
        self.assertEqual(code, failure["error"]["code"], failure)
        return dict(ok=False, **failure)

    def runner(self, *args, expect_ok=True):
        return self.cli(RUNNER, *args, expect_ok=expect_ok)

    def build(self, item="R38", expect_ok=True, code="refused", staged=None):
        if staged is None:
            self.staged_count += 1
            staged = self.work / ("staged-%d" % self.staged_count)
        self.staged = staged
        return self.cli(PACKAGER, "build", "--item", item, "--run-id", self.run_id,
                        "--staged-dir", str(staged), expect_ok=expect_ok, code=code)

    # ---- fixture helpers -------------------------------------------------

    def topic(self, item):
        return next((self.root / "research/topics").glob(item[1:] + "-*"))

    def prompt(self, item):
        return next((self.topic(item) / "prompts").glob("*.prompt.md"))

    def prepare(self, item):
        self.runner("run", "prepare", item, "--run-id", self.run_id, "--actor", "packaging-fixture",
                    "--model", "fixture-model", "--authorization-ref", "offline-test", "--budget", "0")
        self.run_dir = self.root / "research/runs" / item / self.run_id

    def decision_text(self, owns, assumes):
        parameters = ["- owns %s = %s" % pair for pair in sorted(owns.items())]
        parameters += ["- assumes %s = %s" % pair for pair in sorted(assumes.items())]
        return ("## Decision\nSynthetic packaging fixture; no research was performed.\n"
                "re-verify: fixture changes\n\n"
                "### Principles and implementation\nCommit history must stay machine readable.\n\n"
                "## Parameters\n%s\n\n"
                "## Empirical check\nSynthetic command output recorded under evidence.\n\n"
                "## Engines\nSynthetic reports agree.\n" % "\n".join(parameters))

    def audit_text(self, actor, model, family, verdict="approve", findings="none"):
        return ("decision-sha256: %s\nactor: %s\nmodel: %s\nfamily: %s\nverdict: %s\n"
                "unresolved-findings: %s\n\nSynthetic fixture analysis; no real audit performed.\n"
                % (sha(self.run_dir / "review/DECISION.md"), actor, model, family, verdict, findings))

    def identity(self, actor, model, family, file=None):
        record = {"actor": actor, "model": model, "family": family}
        return dict(record, file=file) if file else record

    def restore_audits(self):
        write(self.run_dir / "review/audit-codex.md",
              self.audit_text("audit-codex-%s" % self.run_id, "gpt-5.6-terra", "openai"))
        write(self.run_dir / "review/audit-fable.md",
              self.audit_text("audit-fable-%s" % self.run_id, "claude-fable-5-1", "anthropic"))

    def write_run(self, item, kind, engines, checks=(), owns=None, consumed=None):
        """Fill a prepared run directory with a shape-valid synthetic result."""
        registry = validator._parse_parameters(self.root, [])
        assumes = {name: row["value"] for name, row in registry.items() if row["kind"] == "fixed"}
        assumes.update(consumed or {})
        write(self.run_dir / "review/DECISION.md", self.decision_text(owns or {}, assumes))
        self.restore_audits()
        write(self.run_dir / "review/evidence/audit-commitlint.log", "Synthetic fixture output.\n")
        models = {"codex": "gpt-5.6-terra", "opus": "claude-opus-5", "doxa": "o3-deep-research; sonar-deep-research"}
        families = {"codex": "openai", "opus": "anthropic", "doxa": "openai+perplexity+google"}
        reports = {}
        for engine in engines:
            write(self.run_dir / ("raw/%s.md" % engine), answer(kind))
            reports[engine] = self.identity("research-%s-%s" % (engine, self.run_id), models[engine],
                                            families[engine], "raw/%s.md" % engine)
        # A normalized sibling must win over the engine's original transcript.
        write(self.run_dir / "raw/codex.normalized.md", answer(kind))
        evidence = {}
        for check in checks:
            write(self.run_dir / ("raw/evidence-%s.md" % check), "Synthetic evidence check.\n")
            evidence[check] = self.identity("evidence-%s-%s" % (check, self.run_id), "gpt-5.6-terra",
                                            "openai", "raw/evidence-%s.md" % check)
        identities = {
            "engine_reports": reports,
            "evidence_checks": evidence,
            "synthesis": self.identity("synth-fable-%s" % self.run_id, "claude-fable-5-1", "anthropic"),
            "audits": {
                "empirical": self.identity("audit-codex-%s" % self.run_id, "gpt-5.6-terra", "openai",
                                           "review/audit-codex.md"),
                "judgment": self.identity("audit-fable-%s" % self.run_id, "claude-fable-5-1", "anthropic",
                                          "review/audit-fable.md"),
            },
            "empirical": {"argv": ["cargo", "test"],
                          "cwd": "research/runs/%s/%s/review/empirical-audit/fixture" % (item, self.run_id),
                          "toolchain": "rustc 1.98.0; cargo 1.98.0; macOS 15",
                          "output_log": "review/evidence/audit-commitlint.log", "exit_code": 0},
        }
        write(self.run_dir / "review/identities.json", json.dumps(identities, indent=2) + "\n")

    def overlay(self):
        """A copy of the repository with every staged file applied over it."""
        target = self.work / ("overlay-%d" % self.staged_count)
        shutil.copytree(self.root, target, ignore=IGNORE)
        for path in sorted(self.staged.rglob("*")):
            relative = path.relative_to(self.staged)
            if path.is_file() and relative != Path("manifest.json"):
                write(target / relative, path.read_text())
        return target

    def build_light(self, item):
        """Publish the consumed owner, then package a Light item's run."""
        set_registry_value(self.root, "build-tool-output-shape",
                           "workspace target/ with one bin rs-launch-blueprint and one lib")
        fixtures.accept_fixture(self.root, "R49", kind="crate")
        self.prepare(item)
        value = registry_value(self.root, "build-tool-output-shape")
        self.write_run(item, "pattern", ["codex"], checks=["terra"],
                       consumed={"build-tool-output-shape": value})
        self.build(item)
        return json.loads((self.staged / ("%s/acceptance.json" % self.topic(item).relative_to(self.root))).read_text())

    # ---- tests -----------------------------------------------------------

    def test_build_writes_validating_acceptance_and_manifest(self):
        result = self.build()
        self.assertTrue(result["ok"])
        staged = self.staged
        acceptance = json.loads((staged / "research/topics/38-commit-message-linter/acceptance.json").read_text())
        self.assertEqual(acceptance["item"], "R38")
        self.assertEqual(acceptance["decision_sha256"], sha(staged / "research/topics/38-commit-message-linter/DECISION.md"))
        self.assertEqual([r["engine"] for r in acceptance["engine_reports"]], ["codex", "opus", "doxa"])
        self.assertEqual(acceptance["prompt_sha256"], sha(self.prompt("R38")))
        self.assertEqual(acceptance["reverify"], "fixture changes")
        self.assertEqual(result["result"]["acceptance_sha256"],
                         sha(staged / "research/topics/38-commit-message-linter/acceptance.json"))
        raw = staged / ("research/topics/38-commit-message-linter/raw/codex-%s.md" % self.run_id)
        self.assertEqual(raw.read_text(), (self.run_dir / "raw/codex.normalized.md").read_text())
        log = staged / ("research/topics/38-commit-message-linter/evidence/%s-audit-commitlint.log" % self.run_id)
        self.assertEqual(acceptance["empirical"]["output_log"], str(log.relative_to(staged)))
        self.assertIn("| R38 |", (staged / "research/CLAUDE.md").read_text())
        self.assertIn("| resolved |", [l for l in (staged / "research/CLAUDE.md").read_text().splitlines() if l.startswith("| R38 |")][0])
        self.assertIn("feat, fix", (staged / "docs/port/PARAMETERS.md").read_text())
        manifest = json.loads((staged / "manifest.json").read_text())
        targets = {c["target"] for c in manifest["changes"]}
        self.assertIn("research/topics/38-commit-message-linter/acceptance.json", targets)
        self.assertIn("research/CLAUDE.md", targets)
        self.assertIn("docs/port/PARAMETERS.md", targets)
        self.assertEqual(result["result"]["changes"], len(manifest["changes"]))

    def test_staged_tree_passes_the_strict_validator(self):
        self.build()
        self.assertEqual(validator.validate_topic(self.overlay(), "R38"), [])

    def test_publication_apply_accepts_the_manifest(self):
        self.build()
        result = self.runner("publication", "apply", "--file", str(self.staged / "manifest.json"),
                             "--staged-dir", str(self.staged))
        self.assertTrue(result["ok"], result)
        self.assertEqual(self.runner("run", "status", "R38", "--run-id", self.run_id)["result"]["state"], "published")
        self.assertEqual(validator.validate_topic(self.root, "R38"), [])

    def test_refuses_rejecting_audit_and_stale_prompt(self):
        write(self.run_dir / "review/audit-fable.md",
              self.audit_text("audit-fable-%s" % self.run_id, "claude-fable-5-1", "anthropic",
                              verdict="reject", findings="missing gate"))
        rejected = self.build(expect_ok=False)
        self.assertFalse(rejected["ok"])
        self.assertIn("verdict is 'reject'", rejected["error"]["message"])
        self.restore_audits()
        write(self.prompt("R38"), "changed\n")
        stale = self.build(expect_ok=False)
        self.assertFalse(stale["ok"])
        self.assertIn("prepared prompt copy differs", stale["error"]["message"])
        # An incomplete invocation is a usage error, not a refusal.
        self.cli(PACKAGER, "build", "--item", "R38", expect_ok=False, code="usage")

    def test_refuses_rebuilding_into_a_used_staged_directory(self):
        self.build()
        used, manifest = self.staged, sha(self.staged / "manifest.json")
        write(self.run_dir / "review/audit-fable.md",
              self.audit_text("audit-fable-%s" % self.run_id, "claude-fable-5-1", "anthropic",
                              verdict="reject", findings="missing gate"))
        refused = self.build(expect_ok=False, staged=used)
        self.assertIn("staged directory already holds a staged tree", refused["error"]["message"])
        # The superseded bundle is left whole, so nothing half-rebuilt can publish.
        self.assertEqual(manifest, sha(used / "manifest.json"))
        self.assertIn("verdict: approve",
                      (used / "research/topics/38-commit-message-linter/audit-fable.md").read_text())

    def test_light_item_records_evidence_check(self):
        acceptance = self.build_light("R22")
        self.assertEqual([e["engine"] for e in acceptance["evidence_checks"]], ["terra"])
        self.assertEqual([r["engine"] for r in acceptance["engine_reports"]], ["codex"])
        self.assertEqual(acceptance["parameters"]["consumed"],
                         {"build-tool-output-shape": registry_value(self.root, "build-tool-output-shape")})
        self.assertEqual(acceptance["prerequisites"]["research"],
                         {"R49": sha(self.topic("R49") / "DECISION.md")})
        self.assertEqual(validator.validate_topic(self.overlay(), "R22"), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
