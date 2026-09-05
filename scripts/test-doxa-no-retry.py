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

    def test_replacement_model_is_treated_as_deep_research_when_patched(self):
        self.assertFalse(_verify("--no-patch")["background_model_gpt_5_6_sol"])
        report = _verify()
        self.assertTrue(report["background_model_gpt_5_6_sol"])
        self.assertEqual(report["deep_research_replacements"], ["gpt-5.6-sol"])
        self.assertTrue(report["responses_create_shim"])

    def test_responses_create_shim_rewrites_gpt5_requests_only(self):
        code = (
            "import asyncio, json, sys\n"
            "sys.path.insert(0, 'scripts')\n"
            "import doxa_no_retry\n"
            "captured = []\n"
            "async def fake_create(self, **kw):\n"
            "    captured.append(kw); return 'ok'\n"
            "shim = doxa_no_retry.shim_responses_create(fake_create)\n"
            "asyncio.run(shim(None, model='gpt-5.6-sol', temperature=0.7, tools=[{'type': 'web_search_preview'}, {'type': 'code_interpreter'}], background=True))\n"
            "asyncio.run(shim(None, model='o3', temperature=0.7, tools=[{'type': 'web_search_preview'}]))\n"
            "print(json.dumps(captured))\n"
        )
        result = subprocess.run(
            [str(DOXA_PYTHON), "-c", code],
            capture_output=True,
            text=True,
            timeout=120,
            check=True,
            cwd=ROOT,
        )
        first, second = json.loads(result.stdout)
        self.assertNotIn("temperature", first)
        self.assertEqual(first["tools"], [{"type": "web_search"}, {"type": "code_interpreter"}])
        self.assertTrue(first["background"])
        self.assertEqual(second["temperature"], 0.7)
        self.assertEqual(second["tools"], [{"type": "web_search_preview"}])


if __name__ == "__main__":
    unittest.main()
