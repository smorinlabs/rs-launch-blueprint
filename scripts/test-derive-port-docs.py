#!/usr/bin/env python3
"""CLI regressions for generated-document checks; run with python3."""
import pathlib
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = pathlib.Path(__file__).with_name("derive-port-docs.py")


class DerivedDocumentChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="derive-port-docs-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.port = self.root / "docs/port"
        self.port.mkdir(parents=True)
        (self.port / "COMMONALITY.md").write_text(
            "| ID | Feature | Area | Origin | Verdict | Item | Notes |\n"
            "|---|---|---|---|---|---|---|\n"
            "| F001 | sample | testing-coverage | same | COMMON → REUSE | — | |\n"
        )
        self.files = self.root / "files.txt"
        self.files.write_text("")
        for command in ("coverage", "inventories"):
            result = self.run_cli(command)
            self.assertEqual(result.returncode, 0, result.stderr)

    def run_cli(self, command, check=False):
        args = [sys.executable, str(SCRIPT), command, "--root", str(self.root)]
        if command == "coverage":
            args += ["--files", str(self.files)]
        if check:
            args += ["--check"]
        return subprocess.run(args, capture_output=True, text=True)

    def targets(self):
        return (
            ("coverage", self.port / "COVERAGE.md"),
            ("inventories", self.port / "PY_INVENTORY.md"),
            ("inventories", self.port / "TS_INVENTORY.md"),
        )

    def test_missing_documents_fail_cleanly_without_creating_them(self):
        for command, path in self.targets():
            with self.subTest(path=path.name):
                original = path.read_bytes()
                path.unlink()
                result = self.run_cli(command, check=True)
                try:
                    self.assertEqual(result.returncode, 1, result.stderr)
                    self.assertIn(f"DRIFT: {path} is missing", result.stdout)
                    self.assertNotIn(f"OK: {path}", result.stdout)
                    self.assertEqual(result.stderr, "")
                    self.assertFalse(path.exists())
                finally:
                    path.write_bytes(original)

    def test_stale_documents_fail_without_rewriting_them(self):
        for command, path in self.targets():
            with self.subTest(path=path.name):
                original = path.read_bytes()
                stale = original + b"| stale | stale | stale |\n"
                path.write_bytes(stale)
                result = self.run_cli(command, check=True)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn(f"DRIFT: {path} differs", result.stdout)
                self.assertEqual(path.read_bytes(), stale)
                path.write_bytes(original)

    def test_current_documents_pass(self):
        for command in ("coverage", "inventories"):
            with self.subTest(command=command):
                result = self.run_cli(command, check=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_current_coverage_with_uncovered_files_still_fails(self):
        self.files.write_text("py:unmapped.py\n")
        self.assertEqual(self.run_cli("coverage").returncode, 1)
        path = self.port / "COVERAGE.md"
        original = path.read_bytes()
        result = self.run_cli("coverage", check=True)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("UNCOVERED: py:unmapped.py", result.stdout)
        self.assertEqual(path.read_bytes(), original)

    def test_exclusion_appended_after_table_survives_regeneration(self):
        self.files.write_text("py:generated.lock\n")
        self.assertEqual(self.run_cli("coverage").returncode, 1)
        path = self.port / "COVERAGE.md"
        note = "\n- `*.lock` — generated lockfiles\n\nKeep this explanation.\n"
        path.write_text(path.read_text() + note)
        result = self.run_cli("coverage")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(path.read_text().endswith(note))
        self.assertIn("| py | generated.lock | EXCLUDED: generated lockfiles |", path.read_text())
        self.assertEqual(self.run_cli("coverage", check=True).returncode, 0)

    def test_source_listing_uses_pinned_commit_despite_head_and_index_changes(self):
        repo = self.root / "source"
        repo.mkdir()
        def git(*args):
            return subprocess.run(
                ["git", "-C", str(repo), *args], check=True, capture_output=True, text=True
            ).stdout.strip()
        git("init", "-q")
        (repo / "original.txt").write_text("pinned content\n")
        git("add", "original.txt")
        git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-qm", "source pin")
        revision = git("rev-parse", "HEAD")
        git("rm", "original.txt")
        (repo / "newer.txt").write_text("new content\n")
        git("add", "newer.txt")
        git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "-qm", "source advanced")
        (repo / "staged.txt").write_text("staged content\n")
        git("add", "staged.txt")
        module = runpy.run_path(str(SCRIPT))
        function = module["list_files"]
        with patch.dict(function.__globals__, {"REPOS": {"py": repo},
                        "SOURCE_REVISIONS": {"py": revision}}):
            self.assertEqual(function(None), ["py:original.txt"])
            with patch.dict(function.__globals__["SOURCE_REVISIONS"], {"py": "0" * 40}):
                with self.assertRaisesRegex(SystemExit, "cannot read pinned source py"):
                    function(None)


if __name__ == "__main__":
    unittest.main()
