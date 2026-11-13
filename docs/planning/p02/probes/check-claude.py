"""Bounded, tool-free authenticated model readiness probes; not research."""
import concurrent.futures
import datetime
import json
from pathlib import Path
import subprocess
import time

OUT = Path(__file__).resolve().parent


def probe(model):
    argv = [
        "/Users/stevemorin/.local/bin/claude", "--print", "--safe-mode",
        "--tools", "", "--strict-mcp-config", "--no-session-persistence",
        "--model", model, "--max-budget-usd", "0.10", "--effort", "low",
        "--output-format", "json", "--system-prompt",
        "You are a connectivity test. Reply with the requested token only.",
        "Reply exactly P02_READY_20260904. No tools or research.",
    ]
    start = time.monotonic()
    record = {"argv": argv, "started_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "request_budget_usd": 0.10, "purpose": "authentication and model access only"}
    try:
        result = subprocess.run(argv, cwd=OUT, capture_output=True, text=True, timeout=90)
        record.update(exit_code=result.returncode, stdout=result.stdout, stderr=result.stderr)
    except subprocess.TimeoutExpired:
        record.update(exit_code=None, state="local-timeout; remote completion unknown; do not automatically resubmit")
    record["elapsed_seconds"] = round(time.monotonic() - start, 3)
    path = OUT / f"claude-{model}.json"
    path.write_text(json.dumps(record, indent=2) + "\n")
    return {"model": model, "path": str(path), "exit_code": record.get("exit_code"), "elapsed_seconds": record["elapsed_seconds"]}


if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        for result in pool.map(probe, ["opus", "fable"]):
            print(json.dumps(result), flush=True)
