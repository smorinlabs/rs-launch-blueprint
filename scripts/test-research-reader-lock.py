#!/usr/bin/env python3
"""Black-box refusal checks for readers during publication and recovery."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from research_cli import evidence_read_lock


HERE = Path(__file__).resolve().parent


class ReaderLockTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "root"
        (self.root / "research/runs").mkdir(parents=True)

    def check_readers_refuse(self, phrase):
        commands = [
            [sys.executable, str(HERE / "research_validation.py"), "--json", "tree", str(self.root)],
            [sys.executable, str(HERE / "research_validation.py"), "--json", "topic", str(self.root), "R38"],
            ["/bin/bash", str(HERE / "check-research-tree.sh"), "--require-owner-review", str(self.root)],
        ]
        for command in commands:
            with self.subTest(command=command):
                result = subprocess.run(command, capture_output=True, text=True)
                self.assertEqual(1, result.returncode)
                if "--json" in command:
                    self.assertEqual("", result.stdout)
                    self.assertIn(phrase, json.loads(result.stderr)["error"]["message"])
                else:
                    self.assertEqual("", result.stderr)
                    self.assertIn("FAIL:", result.stdout)
                    self.assertIn(phrase, result.stdout)

    def test_existing_publication_lock_is_never_stolen(self):
        with evidence_read_lock(self.root):
            lock = self.root / "research/runs/.publication.lock"
            owner_before = (lock / "owner.json").read_bytes()
            self.check_readers_refuse("lock is active")
            self.assertEqual(owner_before, (lock / "owner.json").read_bytes())
        self.assertFalse(lock.exists())

    def test_pending_journal_is_preserved_and_readers_refuse(self):
        journal = self.root / "research/runs/.publication-journal.json"
        journal.write_text('{"pending":true}\n')
        self.check_readers_refuse("recovery required")
        self.assertEqual('{"pending":true}\n', journal.read_text())
        self.assertFalse((journal.parent / ".publication.lock").exists())

    def test_symlink_cannot_redirect_reader_lock(self):
        runs = self.root / "research/runs"
        runs.rmdir()
        outside = Path(self.temp.name) / "outside"
        outside.mkdir()
        runs.symlink_to(outside, target_is_directory=True)
        self.check_readers_refuse("refuse symlink")
        self.assertEqual([], list(outside.iterdir()))


if __name__ == "__main__":
    unittest.main()
