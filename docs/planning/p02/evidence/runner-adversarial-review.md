# Offline runner adversarial review

Date: 2026-09-04. Scope: `scripts/research_runner.py`, its offline integration
tests, and `runner-guide.md`. No provider request, paid job, commit, or tag was
created. Evidence fixtures were written only in temporary copied repositories.

**Result: confirmed runner findings fixed; live-provider readiness remains out
of scope.** The former acceptance tests replaced the validator with functions
that always returned success. Those tests could not prove first publication.
The replacement suite uses the actual Python validator and the actual structural
checker, including owner-review enforcement. A copied production tree publishes
its first synthetic R38 acceptance from `open` and passes the full checker.
This is a software integration test, not the binding research pilot.

| Finding | Fixed behavior | Discriminating evidence |
|---|---|---|
| High: mutable saved prompt/policy/parameter/prerequisite copies were trusted | Submission intent and publication rehash every preserved input copy; prerequisite keys and current values are checked | `test_mutated_saved_snapshots_refused`; `test_parameter_and_prerequisite_freshness_discriminate` |
| High: symlinked run directories and noncanonical target aliases could bypass confinement or duplicate detection | Run/lock/raw paths reject symlink components; publication accepts canonical relative paths and a bounded target set | `test_symlink_run_and_raw_escape_refused`; `test_duplicate_alias_and_escape_targets_refused` |
| High: later recovery conflict could occur after earlier targets had already been rewritten | Recovery preflights the entire journal, every target, expected/desired hashes, and recorded inputs before writes | `test_recovery_preflights_all_cas_before_any_write`; `test_journal_target_escape_refused_before_writes`; `test_publication_and_recovery_refuse_changed_inputs` |
| High: publication and admission could overlap or continue through an incomplete journal | The publisher owns the shared lock across candidate validation and apply; prepare, intent and queue admission share the barrier; recovery is explicit | `test_writer_lock_blocks_admission_and_publication`; `test_crash_recovery_blocks_readers_and_rolls_forward` |
| High: validating one acceptance could leave other resolved topics stale or permit invalid ledger edits | The complete candidate validates all resolved topics and must pass `check-research-tree.sh --require-owner-review`; missing checkers refuse | `test_corrupt_ledger_and_missing_checker_fail_closed`; `test_revision_preserves_history_and_reopens_stale_consumer` |
| High: compare-and-swap alone allowed deleting prior decision history | A revision requires a dated current entry and the previous decision bytes verbatim under `## Supersedes` | The history regression first proves its history-deleting candidate is otherwise validator-valid, then verifies publisher refusal |
| Medium: operation mirrors could disagree with durable manifest state, and one success could mark a three-engine run collected | The manifest is authoritative; events preserve prior operation records; all required engines must succeed before `collected` | `test_partial_and_failed_operation_state_survives_mirror_loss` |
| Medium: queue order counted only direct consumers and conflated evidence collection with acceptance | Queue uses transitive descendants, excludes existing pending/collected runs, requires validated resolved prerequisites, and keeps acceptance-only edges out of research admission | `test_queue_research_and_acceptance_dependencies_differ`; production R38 fixture |
| Test gap: an unknown operation was never exercised through reconciliation | Recording the recovered ID permits later collection without another intent; original raw bytes remain retained | `test_unknown_reconciliation_and_raw_preservation` |
| Medium: historical collected/prepared runs blocked an accepted item forever after reopening | Publication and recovery finalize an immutable `published` run receipt; queue ignores published history while still blocking new pending work | `test_published_run_does_not_block_reopened_item`; `test_recovery_finalizes_receipt_after_all_targets_written` |

## Validation receipt

From the repository root:

```text
/Users/stevemorin/.local/bin/uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/test-research-runner.py
Ran 19 tests
OK
```

Final integration rerun after CLI reader locking and published-run recovery:
19 tests passed in 23.715 seconds. The reader tests also verify JSON `tree` and the public shell checker
refuse an active writer, and JSON `tree` refuses an incomplete journal with no
success output. The strengthened two-reader checks passed in a focused rerun.

The production-tree case includes an independent post-publication run of:

```text
/bin/bash <temporary-repository>/scripts/check-research-tree.sh --require-owner-review <temporary-repository>
OK: research tree structure valid
```

Six deliberate code mutations were independently detected by the corresponding
tests: disabling saved-copy hashes, disabling freshness checks, writing during
recovery preflight, removing the publication lock, disabling decision history
preservation, and ignoring structural-check failure. Each mutated runner
returned a failing test process; the unmodified runner passed. The durable
mutation driver is `docs/planning/p02/evidence/runner-mutation-check.py`; tests also accept
`RESEARCH_RUNNER_TEST_SCRIPT` to point at an isolated candidate runner.

## Limits and operating contract

- No provider adapter exists. Submission deduplication, model identity, billing,
  SDK retries, or provider inventory reconciliation were not tested live.
- Atomic file replacement plus a recovery journal is not simultaneous visibility
  of every file. Participating CLI readers must hold the same publication lock.
  Direct validator APIs remain lock-neutral for their lock-owning caller.
- Filesystem editors outside this protocol can bypass its locks. Tests cover
  pre-existing symlinks, conflicts, and injected interruption; they do not claim
  resistance to a malicious process replacing paths between filesystem calls,
  or a physical power-loss test.
- Waiting age, host capacity, acceptance backlog, and paid limits remain
  controller policy. The local queue orders owners, then transitive descendants,
  then stable item ID. `collected` means engine collection, not accepted research.
- Changed shared inputs during interrupted publication require inspection. Locks
  are never stolen automatically, and a conflicting journal remains intact.
- Validators establish record integrity. Synthetic logs and approving fixture
  text do not establish execution truth, source quality, or architectural fitness.

Implementation entry points: `freshness_errors`, `update_operation`, `queue`,
`check_history`, `_recover_unlocked`, and `_publish_unlocked` in
`scripts/research_runner.py`. The executable evidence is
`scripts/test-research-runner.py`; operator behavior is documented in
`docs/planning/p02/runner-guide.md`.
