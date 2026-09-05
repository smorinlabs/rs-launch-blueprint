"""Reproduce planning findings in disposable copies, without changing the tree."""
import json
import io
import tarfile
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[4]
BASE_COMMIT = "2f3569051af2c2089f60f6cad129bc6e55482c30"
OUT = Path(__file__).with_name("contract-reproductions.json")


def check(root):
    result = subprocess.run(
        ["/bin/bash", "scripts/check-research-tree.sh", "--require-owner-review"],
        cwd=root, capture_output=True, text=True, check=False,
    )
    return {"exit_code": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


with tempfile.TemporaryDirectory(prefix="p02-contract-probes-") as tmp:
    root = Path(tmp)
    archive = subprocess.check_output(["git", "archive", BASE_COMMIT, "scripts", "research", "docs/port"], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        source.extractall(root, filter="data")
    records = {"source_commit": BASE_COMMIT}
    records["valid_baseline"] = check(root)
    assert records["valid_baseline"]["exit_code"] == 0

    topic = root / "research/topics/47-contributors-recipe-mode"
    prompt = topic / "prompts/contributors-recipe-mode.prompt.md"
    retry = prompt.with_name("contributors-recipe-mode.narrowed.prompt.md")
    shutil.copyfile(prompt, retry)
    records["C11_documented_retry_filename"] = check(root)
    assert records["C11_documented_retry_filename"]["exit_code"] == 1
    assert "prompt not linked from index" in records["C11_documented_retry_filename"]["stdout"]
    retry.unlink()

    index = root / "research/CLAUDE.md"
    lines = index.read_text().splitlines()
    for n, line in enumerate(lines):
        if line.startswith("| R47 |"):
            assert line.endswith("| open |")
            lines[n] = line.removesuffix("| open |") + "| resolved |"
    index.write_text("\n".join(lines) + "\n")
    (topic / "DECISION.md").write_text("## Decision\n\n## Parameters\n\n## Empirical check\n")
    for filename in ["audit-codex.md", "audit-fable.md"]:
        (topic / filename).write_text("REJECT: no executed evidence or substantive decision.\n")
    records["C12_empty_decision_reject_audits"] = check(root)
    assert records["C12_empty_decision_reject_audits"]["exit_code"] == 0

    fields = ["Landscape", "Principles and implementation", "Recommendation", "Members",
              "Compatibility", "Parameters", "Migration implications", "Validation strategy",
              "Confidence & re-verify trigger", "Sources"]
    empty_answer = root / "empty-answer.md"
    empty_answer.write_text("```markdown\n" + "\n".join("### " + f for f in fields) + "\n```\n")
    result = subprocess.run(["/bin/bash", "scripts/check-answer-shape.sh", str(empty_answer), "bundle"],
                            cwd=root, capture_output=True, text=True, check=False)
    records["C10_fenced_empty_answer"] = {"exit_code": result.returncode,
                                            "stdout": result.stdout, "stderr": result.stderr}
    assert result.returncode == 0
    OUT.write_text(json.dumps(records, indent=2) + "\n")
    print(json.dumps({k: v["exit_code"] for k, v in records.items() if isinstance(v, dict)}))
