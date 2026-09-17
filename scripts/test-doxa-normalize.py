#!/usr/bin/env python3
"""Regressions for the Doxa report normalizer; run with python3.

Every case regenerates the per-provider twins and the merged twin for a
committed Wave 0 run, writing only into a temporary directory: the run
directories are read-only inputs.  The cases assert, for each of the three item
kinds, that the merged twin has zero validator errors and that no content line
of any provider twin is lost, and they hold the per-provider twins to
byte-identity with the twins the (now lost) Wave 0 script produced.

R69 is the regression that matters most: its committed merged twin refused
publication on 2026-09-17 with 60 `#####` member fields orphaned outside the
`### Members` window, and the rewrite must not reproduce that.
"""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE / "doxa_normalize.py"
ROOT = HERE.parent
RUNS = ROOT / "research" / "runs"
PROVIDERS = ["openai", "perplexity", "gemini"]

# item, run directory, kind, providers whose own twin is expected to fail the
# single-answer shape check (Perplexity drops top-level fields on most prompts)
CASES = [
    ("R42", "2026-09-05T155503Z-4141a35b69e0", "bundle", {"perplexity"}),
    ("R49", "2026-09-05T155504Z-2107cffb3ecf", "crate", set()),
    ("R25", "2026-09-05T164357Z-eec460755121", "pattern", {"perplexity"}),
    ("R69", "2026-09-12T204004Z-d02022bf6f42", "bundle", set()),
]

sys.path.insert(0, str(HERE))
from research_validation import validate_answer_text  # noqa: E402


def content_lines(path):
    """Non-blank, non-heading lines: what a lossless regrouping must preserve."""
    return [line for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")]


class Normalizer(unittest.TestCase):
    def run_cli(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT)] + [str(a) for a in args],
                              capture_output=True, text=True)

    def normalize(self, item, stamp, kind):
        """Regenerate every twin for one committed run inside a temp directory."""
        source = RUNS / item / stamp
        self.assertTrue(source.is_dir(), "missing committed run %s" % source)
        temp = tempfile.TemporaryDirectory(prefix="doxa-normalize-test-")
        self.addCleanup(temp.cleanup)
        work = pathlib.Path(temp.name) / item / stamp
        (work / "raw").mkdir(parents=True)
        shutil.copytree(source / "doxa" / "research-outputs", work / "doxa" / "research-outputs")
        record = work / "doxa" / "normalization.json"
        results = {}
        for provider in PROVIDERS:
            saved = sorted((work / "doxa" / "research-outputs").glob("*_%s_*.md" % provider))
            self.assertEqual(len(saved), 1, "expected one %s saved file in %s" % (provider, source))
            twin = work / "raw" / ("doxa-%s.normalized.md" % provider)
            results[provider] = self.run_cli(
                "provider", "--saved", saved[0], "--provider", provider,
                "--kind", kind, "--out", twin, "--record", record)
        merged = work / "raw" / "doxa.normalized.md"
        results["merge"] = self.run_cli(
            "merge", "--run-dir", work, "--kind", kind,
            "--out", merged, "--record", record, "--item", item)
        return source, work, merged, record, results

    def test_every_kind_regroups_losslessly(self):
        for item, stamp, kind, expected_failures in CASES:
            with self.subTest(item=item, kind=kind):
                source, work, merged, record, results = self.normalize(item, stamp, kind)

                for provider in PROVIDERS:
                    result = results[provider]
                    self.assertIn(result.returncode, (0, 1), result.stderr)
                    failed = result.returncode != 0
                    self.assertEqual(failed, provider in expected_failures,
                                     "%s %s twin shape: %s" % (item, provider, result.stdout))
                    # the Wave 0 twins are the reference output for this step
                    self.assertEqual(
                        (work / "raw" / ("doxa-%s.normalized.md" % provider)).read_bytes(),
                        (source / "raw" / ("doxa-%s.normalized.md" % provider)).read_bytes(),
                        "%s %s twin differs from the committed Wave 0 twin" % (item, provider))

                self.assertEqual(results["merge"].returncode, 0,
                                 results["merge"].stdout + results["merge"].stderr)
                errors = validate_answer_text(merged.read_text(encoding="utf-8"), kind)
                self.assertEqual(errors, [], "%s merged twin shape errors" % item)

                # census: every content line of every provider twin survives
                regrouped = set(merged.read_text(encoding="utf-8").splitlines())
                written = json.loads(record.read_text(encoding="utf-8"))
                for provider in PROVIDERS:
                    twin = work / "raw" / ("doxa-%s.normalized.md" % provider)
                    lost = [line for line in content_lines(twin) if line not in regrouped]
                    self.assertEqual(lost, [], "%s %s lost %d content line(s)"
                                     % (item, provider, len(lost)))
                    self.assertEqual(
                        written["providers"][provider]["content_lines_missing_from_regrouped"], 0)
                self.assertEqual(written["regrouped"]["shape"], "OK: validation passed")

    def test_r69_members_window_stays_open(self):
        """The defect that refused R69's publication must not recur."""
        item, stamp, kind, _ = CASES[3]
        _, _, merged, _, _ = self.normalize(item, stamp, kind)
        lines = merged.read_text(encoding="utf-8").splitlines()
        start = lines.index("### Members")
        end = next(index for index in range(start + 1, len(lines))
                   if lines[index].startswith(("# ", "## ", "### ")))
        orphans = [line for index, line in enumerate(lines)
                   if line.startswith("##### ") and not start < index < end]
        self.assertEqual(orphans, [], "%d H5 member field(s) outside '### Members'" % len(orphans))
        members = [line for line in lines[start:end] if line.startswith("#### ")]
        self.assertEqual(len(members), len(set(members)))
        self.assertGreaterEqual(len(members), 13)

    def test_prompt_echo_containing_a_fence_does_not_leak(self):
        """A prompt carrying its own fence must not close the echo early."""
        sys.path.insert(0, str(HERE))
        from doxa_normalize import split_saved

        prompt = "# Prompt title\n\n```toml\nedition = \"2024\"\n```\n\n## Answer template\n"
        saved = ("---\nprompt: # Prompt title\nmode: all_deep_research\nprovider: openai\n"
                 "model: test-model\noperation_id: op-1\n---\n\n### Prompt\n\n```\n"
                 "System: research this.\n\nUser: " + prompt + "```\n\n### Landscape\n\nBody.\n")
        metadata, body = split_saved(saved, prompt)
        self.assertEqual(metadata["operation_id"], "op-1")
        self.assertEqual(body, ["### Landscape", "", "Body."])
        # without the prompt the inner fence closes the echo early and prompt
        # text leaks into the body, which is why `provider` reads
        # <run>/inputs/prompt.md
        self.assertIn("## Answer template", "\n".join(split_saved(saved)[1]))

    def test_check_subcommand_reports_both_outcomes(self):
        good = RUNS / "R42/2026-09-05T155503Z-4141a35b69e0/raw/doxa-openai.normalized.md"
        self.assertEqual(self.run_cli("check", "--file", good, "--kind", "bundle").returncode, 0)
        bad = RUNS / "R42/2026-09-05T155503Z-4141a35b69e0/raw/doxa-perplexity.normalized.md"
        result = self.run_cli("check", "--file", bad, "--kind", "bundle")
        self.assertEqual(result.returncode, 1)
        self.assertIn("H3 fields must be exactly in order", result.stdout)


if __name__ == "__main__":
    unittest.main()
