#!/usr/bin/env python3
"""CLI regressions for generated-document checks; run with python3."""
import pathlib
import subprocess
import sys
import tempfile
import unittest

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
                path.write_bytes(original + b"stale\n")
                result = self.run_cli(command, check=True)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn(f"DRIFT: {path} differs", result.stdout)
                self.assertEqual(path.read_bytes(), original + b"stale\n")
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


if __name__ == "__main__":
    unittest.main()
