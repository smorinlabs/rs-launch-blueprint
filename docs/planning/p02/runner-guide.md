# P02 durable runner

`scripts/research_runner.py` is an offline state store. It never invokes Doxa,
Claude, Codex, or any paid provider. A worker uses `run prepare`, `run intent`, and
`run submitted` around a provider call; a later collector uses `run collect` with the
same operation ID. If an accepted request loses its ID, record `unknown`: do
not submit it again until the provider inventory reconciles the request ID.

Run from the repository root with
`uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --help`.
All automation should add `--json` (or `--output json`). A successful command
writes exactly one JSON object to stdout. An error writes exactly one JSON error
object to stderr and leaves stdout empty. Usage errors exit 2; ordinary refusals
exit 1.

```text
run prepare R38 --actor luna --model <actual-model> --authorization-ref <approval> --budget <remaining>
run intent R38 --run-id <run> --provider doxa --actor luna --model <actual-model>
run submitted R38 --run-id <run> --provider doxa --operation-id <provider-id> --actor luna --model <actual-model>
run collect R38 --run-id <run> --provider doxa --state succeeded --raw-file inputs/returned.md --actor luna --model <actual-model>
```

Each run is isolated in `research/runs/R##/<run-id>/`. `inputs/prompt.md` is an
immutable copy whose hash is stored in `manifest.json`; provider state lives in
`manifest.json`, with convenience mirrors in `operations/`. The manifest event
history preserves each previous operation record, including returned IDs and
failure reasons. Locks are atomic directories and are never stolen automatically.
The wrapper records no SDK retry guarantee: hidden provider retries are
unverified until a provider capability review records them. Collected raw bytes
receive a content-hash filename and are never overwritten.
`queue list` admits only research prerequisites. `acceptance_after` remains a
publication/acceptance constraint, so it does not create a research barrier.
Queue ordering puts parameter owners first, then items with the most transitive
research descendants, then item ID. Waiting age, worker capacity, the two-item
acceptance backlog limit, and paid budgets remain controller decisions. Prepared,
active, partial, and collected runs are not admitted again. Failed provider
records pause that provider's queue admission. A run is `collected` only after
every required research engine has succeeded; that state does not mean its
evidence has been accepted.

Successful publication changes its original run to `published` and stores a
receipt with the transaction ID and accepted decision/evidence hashes. Recovery
finishes that receipt before deleting the journal. Published runs retain their
reports and reject further operation changes. They do not block queue admission
when an item is later reopened; new research uses a new prepared run.

`publication apply` accepts a reviewed JSON manifest and a staged directory.
Use `--file <path>` or its alias `--manifest <path>`; `--file -` reads reviewed
JSON from standard input. Its only
targets are the item’s `DECISION.md`, `acceptance.json`, `audit-codex.md`,
`audit-fable.md`, unique `raw/<engine>-<run-id>.md` reports, and unique
`evidence/<name>.log` files, plus `research/CLAUDE.md`,
`docs/port/PARAMETERS.md`, and `docs/port/COMMONALITY.md`. Every target has an
expected SHA-256, or `missing` for a new file. Paths must use their canonical
relative spelling; aliases such as `research/./CLAUDE.md` are refused. Raw and
evidence targets are direct files in those directories and cannot replace prior
files. The runner validates every resolved topic in a copied candidate tree and
requires `check-research-tree.sh --require-owner-review` to pass. A missing
validator or structural checker refuses publication.

The publisher holds the writer lock throughout validation and publication.
Each file replacement is atomic; the collection of replacements uses a durable
journal. `run prepare`, `run intent`, and `queue list` refuse another active
publisher or an incomplete journal. Recovery is explicit with `publication
recover`; a new `publication apply` never silently recovers an older transaction.
The validator's `tree` and `topic` commands and the public structural checker
hold the same lock through their complete read and result, so they refuse a
partial publication. Their temporary coordination directories do not alter
the evidence files. Direct validator APIs require a lock-owning caller.
Recovery checks every target, desired hash, expected current hash, and recorded
input hash before writing any remaining file. An intervening edit causes refusal
and preserves the journal for inspection. After a process dies while holding a
lock, inspect its recorded PID and transaction before manually removing that
stale lock; the runner never steals it.

Decision revisions need a dated current entry, such as `# 2026-09-04`, followed
by `## Supersedes` containing the previous `DECISION.md` bytes verbatim. Reopen
affected consumers in the staged index when their accepted input hashes become
stale. The publisher rejects a candidate that leaves those consumers resolved.

External execution remains disabled until paid authorization is recorded.
Paid Doxa calls go through `scripts/doxa_no_retry.py` with the pilot config
(`docs/planning/p02/doxa-pilot.config.toml`); see
[paid-envelope.md](paid-envelope.md) for the exact invocation and the approval
it needs. A publication manifest names the
prepared `run_id`; the runner refuses it if the copied prompt, that item's
execution-policy record, fixed or consumed parameter values, or accepted
prerequisite snapshots are no longer current. It retains full policy, index,
and parameter copies for provenance without blocking unrelated parallel work.
Every saved input copy is checked against its recorded hash before submission
intent and publication. The recovery journal uses a stricter shared-file hash
check so edits during an interrupted transaction require inspection.

The locks coordinate these tools; they cannot prevent an unrelated program or
manual filesystem editor from bypassing the protocol. Hash checks protect
recorded integrity, not the truth of synthetic or externally produced evidence.
Run `scripts/test-research-runner.py` with the same offline Python command above
to exercise real-validator publication, full-tree R38 fixtures, recovery, and
refusal cases. These fixtures do not satisfy the binding paid R38 pilot.

## Publication manifest and worker receipt

A publication manifest identifies the prepared run and every staged file. For
example, this fragment proposes a first decision file; a real first acceptance
also supplies all required raw reports, empirical output, audits, acceptance
metadata, registry changes and the resolved index row:

```json
{
  "item": "R38",
  "run_id": "<run_id returned by run prepare>",
  "dependency_hashes": {},
  "changes": [
    {
      "target": "research/topics/38-commit-message-linter/DECISION.md",
      "expected_sha256": "missing",
      "staged": "DECISION.md"
    }
  ]
}
```

`staged` is relative to `--staged-dir`; `target` is relative to the repository.
For an existing target, replace `missing` with the SHA-256 of its current bytes.
`dependency_hashes` is required even when empty. It records additional
repository-relative inputs and expected hashes. The runner independently checks
the prepared prompt, policy, fixed/consumed parameters and prerequisite evidence.
The incomplete example above is refused by the acceptance validator.

`scripts/research_package.py build --item R38 --run-id <run> --staged-dir <dir>`
assembles that manifest and the whole acceptance bundle from a completed run
directory instead of by hand, using the same JSON contract and offline command
as the runner. It reads `research/runs/R##/<run-id>/`: `review/DECISION.md`,
`review/audit-codex.md`, `review/audit-fable.md`, each `raw/<engine>.md` (or
its `raw/<engine>.normalized.md` sibling when the run recorded one), every
`review/evidence/*.log`, and `review/identities.json`. That identities file
records the `actor`, `model`, `family` and run-relative `file` of each engine
report, each Light evidence check and both audits, plus the synthesis identity
and the `argv`, `cwd`, `toolchain`, `output_log` and `exit_code` of the
empirical rerun. The tool copies those files into `<dir>` under their published
paths (`raw/<engine>-<run-id>.md`, `evidence/<run-id>-<name>.log`), marks the
item `resolved` in `research/CLAUDE.md`, copies every `- owns <param> = <value>`
decision line into that parameter's registry value column, derives
`acceptance.json` under the acceptance schema, and writes `<dir>/manifest.json`
listing only the staged files whose bytes differ from the repository. It
refuses a run whose copied prompt is no longer current, an audit whose verdict
is not `approve` or whose unresolved findings are not `none`, a missing
identity, evidence or prerequisite decision, and a prerequisite that is not an
accepted resolved topic. It never writes inside the repository and takes no
publication lock: review the staged tree, then publish it with
`publication apply`, which repeats every check while holding that lock.

A short wrapper returns only the run directory, state, operation ID when known,
output-file paths and hashes, and the next required action. Full provider results
stay in the run directory. Record the approved currency and remaining amount
in `--budget`, and the approval's durable reference in `--authorization-ref`.
These fields are records for the controller; the local runner cannot enforce
an external provider's spending ceiling.
