"""Deliberately disable isolated runner guards and require discriminating RED tests."""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[4]
source = (root / 'scripts/research_runner.py').read_text()
mutations = [
    ('snapshot-integrity', 'for label, name in snapshots.items():', 'for label, name in []:', 'test_mutated_saved_snapshots_refused'),
    ('freshness', '    hashes = manifest.get("input_hashes", {})', '    return []\n    hashes = manifest.get("input_hashes", {})', 'test_parameter_and_prerequisite_freshness_discriminate'),
    ('recovery-preflight', '        prepared.append((destination, desired))', '        atomic(destination, desired)\n        prepared.append((destination, desired))', 'test_recovery_preflights_all_cas_before_any_write'),
    ('writer-lock', 'def publish(args: argparse.Namespace, root: Path) -> dict[str, Any]:\n    with DirLock(publication_lock(root)):', 'def publish(args: argparse.Namespace, root: Path) -> dict[str, Any]:\n    if True:', 'test_writer_lock_blocks_admission_and_publication'),
    ('history', 'def check_history(destination: Path, desired: bytes) -> None:\n', 'def check_history(destination: Path, desired: bytes) -> None:\n    return\n', 'test_revision_preserves_history_and_reopens_stale_consumer'),
    ('structural-check', '        if checked.returncode: raise RunnerError(', '        if False: raise RunnerError(', 'test_corrupt_ledger_and_missing_checker_fail_closed'),
]
for name, old, new, test in mutations:
    assert source.count(old) == 1, name
    with tempfile.TemporaryDirectory() as directory:
        mutant = Path(directory) / 'research_runner.py'
        mutant.write_text(source.replace(old, new))
        environment = os.environ.copy()
        environment['RESEARCH_RUNNER_TEST_SCRIPT'] = str(mutant)
        environment['PYTHONPATH'] = str(root / 'scripts')
        result = subprocess.run([sys.executable, str(root / 'scripts/test-research-runner.py'), 'RunnerTests.' + test], capture_output=True, text=True, env=environment)
        assert result.returncode == 1 and 'FAIL:' in result.stderr, (name, result.stdout, result.stderr)
        print('RED confirmed:', name, '->', test)
print('PASS: all six deliberately disabled safety gates were detected')
