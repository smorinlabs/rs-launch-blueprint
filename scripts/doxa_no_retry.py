#!/usr/bin/env python3
"""Run the Doxa CLI with hidden provider create-retries disabled.

P02 runbook §3 forbids resubmitting a paid research request merely because a
caller timed out. Doxa's OpenAI and Gemini providers wrap their create calls in
tenacity (three attempts) and the OpenAI SDK adds two more retries of its own;
neither path sends an idempotency key, so an ambiguous timeout can create a
duplicate paid job that no list endpoint can reconcile afterwards. Perplexity's
async submit reuses one idempotency key across its retries, but the API only
documents the key's purpose, not its deduplication semantics. This launcher
therefore rebinds every provider submit wrapper to a single attempt before
handing control to the normal Doxa CLI; a failed create is reported, recorded
and reconciled by the controller instead of being retried blindly.

Usage (always through the Doxa virtual environment):

    <doxa-venv>/bin/python scripts/doxa_no_retry.py --verify [--json] [--no-patch]
    <doxa-venv>/bin/python scripts/doxa_no_retry.py <any doxa arguments>

`--verify` prints the effective retry settings and exits without contacting a
provider. `--no-patch` shows the unpatched settings for comparison.
"""

from __future__ import annotations

import json
import sys

PATCH_TARGETS = (
    ("doxa_research.providers.openai", "OpenAIProvider", "_submit_with_retry"),
    ("doxa_research.providers.gemini", "GeminiProvider", "_deep_research_submit_with_retry"),
    ("doxa_research.providers.gemini", "GeminiProvider", "_submit_with_retry"),
    ("doxa_research.providers.perplexity", "PerplexityProvider", "_submit_with_retry"),
    ("doxa_research.providers.perplexity", "PerplexityProvider", "_submit_async_with_retry"),
)


def _import(path: str):
    module = __import__(path, fromlist=["_"])
    return module


def apply_patches() -> None:
    import openai
    from tenacity import stop_after_attempt

    original_init = openai.AsyncOpenAI.__init__

    def init_without_sdk_retries(self, *args, **kwargs):
        kwargs["max_retries"] = 0
        return original_init(self, *args, **kwargs)

    init_without_sdk_retries.__doxa_no_retry__ = True  # type: ignore[attr-defined]
    openai.AsyncOpenAI.__init__ = init_without_sdk_retries  # type: ignore[method-assign]

    for module_name, class_name, attr in PATCH_TARGETS:
        cls = getattr(_import(module_name), class_name)
        wrapped = getattr(cls, attr)
        setattr(cls, attr, wrapped.retry_with(stop=stop_after_attempt(1)))


def effective_settings() -> dict:
    import importlib.metadata as metadata

    import openai
    from google import genai
    from google.genai import types as genai_types

    report: dict = {
        "versions": {
            name: metadata.version(name)
            for name in ("doxa-research", "openai", "google-genai", "tenacity", "httpx")
        },
        "python": sys.version.split()[0],
        "openai_sdk_max_retries": openai.AsyncOpenAI(api_key="verify-only").max_retries,
        "tenacity_submit_attempts": {},
    }
    for module_name, class_name, attr in PATCH_TARGETS:
        cls = getattr(_import(module_name), class_name)
        stop = getattr(cls, attr).retry.stop
        report["tenacity_submit_attempts"][f"{class_name}.{attr}"] = getattr(
            stop, "max_attempt_number", None
        )
    report["perplexity_async_idempotency_key"] = (
        "uuid4 generated once per submission; documented purpose only, dedup semantics unspecified"
    )
    client = genai.Client(
        api_key="verify-only", http_options=genai_types.HttpOptions(timeout=1000)
    )
    report["google_genai_sdk_attempts"] = getattr(
        client._api_client._async_retry.stop, "max_attempt_number", None
    )
    report["patched"] = getattr(openai.AsyncOpenAI.__init__, "__doxa_no_retry__", False)
    return report


def main(argv: list[str]) -> int:
    if argv and argv[0] == "--verify":
        flags = set(argv[1:])
        unknown = flags - {"--json", "--no-patch"}
        if unknown:
            sys.stderr.write(f"unknown --verify flags: {sorted(unknown)}\n")
            return 2
        if "--no-patch" not in flags:
            apply_patches()
        report = effective_settings()
        if "--json" in flags:
            print(json.dumps(report, sort_keys=True))
        else:
            for key, value in sorted(report.items()):
                print(f"{key}: {value}")
        return 0
    apply_patches()
    from doxa_research.cli import main as doxa_main

    sys.argv = [sys.argv[0], *argv]
    return doxa_main()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
