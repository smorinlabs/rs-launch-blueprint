#!/usr/bin/env python3
"""Regression tests for scripts/doxa_no_retry.py.

The launcher must run under the Doxa virtual environment. The interpreter is
taken from DOXA_PYTHON or the recorded default; the tests are skipped with an
explicit reason when it is absent so the offline suite stays green elsewhere.
"""

from __future__ import annotations

import json
import os
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
LAUNCHER = ROOT / "scripts" / "doxa_no_retry.py"
DOXA_PYTHON = pathlib.Path(
    os.environ.get("DOXA_PYTHON", "/Users/stevemorin/c/doxa-research/.venv/bin/python")
)
PATCHED_TARGETS = {
    "OpenAIProvider._submit_with_retry",
    "GeminiProvider._deep_research_submit_with_retry",
    "GeminiProvider._submit_with_retry",
    "PerplexityProvider._submit_with_retry",
    "PerplexityProvider._submit_async_with_retry",
}


def _verify(*flags: str) -> dict:
    result = subprocess.run(
        [str(DOXA_PYTHON), str(LAUNCHER), "--verify", "--json", *flags],
        capture_output=True,
        text=True,
        timeout=120,
        check=True,
    )
    return json.loads(result.stdout)


@unittest.skipUnless(DOXA_PYTHON.exists(), f"Doxa interpreter not found: {DOXA_PYTHON}")
class NoRetryLauncherTests(unittest.TestCase):
    def test_unpatched_settings_show_the_hidden_retries(self):
        report = _verify("--no-patch")
        self.assertFalse(report["patched"])
        self.assertEqual(report["openai_sdk_max_retries"], 2)
        self.assertEqual(set(report["tenacity_submit_attempts"]), PATCHED_TARGETS)
        self.assertTrue(all(n == 3 for n in report["tenacity_submit_attempts"].values()))

    def test_patched_settings_allow_exactly_one_create_attempt(self):
        report = _verify()
        self.assertTrue(report["patched"])
        self.assertEqual(report["openai_sdk_max_retries"], 0)
        self.assertEqual(set(report["tenacity_submit_attempts"]), PATCHED_TARGETS)
        self.assertTrue(all(n == 1 for n in report["tenacity_submit_attempts"].values()))
        self.assertEqual(report["google_genai_sdk_attempts"], 1)
        self.assertIn("openai", report["versions"])

    def test_unknown_verify_flag_is_a_usage_error(self):
        result = subprocess.run(
            [str(DOXA_PYTHON), str(LAUNCHER), "--verify", "--bogus"],
            capture_output=True,
            text=True,
            timeout=120,
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, "")

    def test_cli_passthrough_reaches_doxa_without_a_provider_call(self):
        result = subprocess.run(
            [str(DOXA_PYTHON), str(LAUNCHER), "--version"],
            capture_output=True,
            text=True,
            timeout=120,
            check=True,
        )
        self.assertIn("Doxa Research", result.stdout)


if __name__ == "__main__":
    unittest.main()
