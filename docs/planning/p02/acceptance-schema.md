# P02 acceptance evidence schema

This schema describes the evidence that permits a topic to be marked
`resolved`. It makes a recorded execution, its inputs, and its independent
review inspectable. File hashes and field checks establish the integrity of
the record; they do not by themselves prove that a command actually executed.

`scripts/research_validation.py` validates evidence without changing it. Its
CLI creates a temporary publication lock while reading; its import APIs are
lock-neutral for a caller that already holds the writer lock. Its import-safe
API is `validate_execution_policy(root)` for the policy and
`validate_topic(root, item)` for a resolved topic. Both return a list of
diagnostic strings. Its `answer`, `tree`, and `topic` command modes offer the
same checks. With `--json`, success writes one JSON object to standard output;
failure writes one JSON error object to standard error and exits 1.

## `research/EXECUTION.json`

The policy file has this exact top-level shape:

```json
{
  "schema_version": 1,
  "approved_on": "YYYY-MM-DD",
  "pilot": "R38",
  "items": {
    "R01": {
      "tier": "light | focused | deep",
      "engines": ["codex"],
      "evidence_checks": ["terra"],
      "acceptance_after": ["R##"]
    }
  }
}
```

`items` contains every and only current index ID. Values have exactly the four
shown keys. `tier` is lowercase. A Light item has `engines: ["codex"]` and
`evidence_checks: ["terra"]`; a Focused item has `["codex", "opus"]` and an
empty evidence-check array; a Deep item has `["codex", "opus", "doxa"]` and
an empty evidence-check array. The pilot is R38 in the production tree and
uses all three engines despite its Focused tier. `acceptance_after` lists only
other current IDs and can be empty.

Every prompt mirrors its item policy under `## Couplings`, once each and in
this literal form:

```markdown
- effort: focused
- engines: codex, opus
- evidence-checks:
- acceptance-after: R71
```

For an empty list, retain the label with no value. The validator checks policy
mirrors but treats only registry `consumes` and the non-owner related-to-owner
rule as research graph edges. `acceptance-after` belongs only to the
publication/acceptance graph, where it is cycle-checked separately; it does
not make every `related` reference binding.

## Topic `acceptance.json`

Place one file at `research/topics/<nn>-<slug>/acceptance.json` for every
resolved item. It has exactly these top-level fields:

```json
{
  "item": "R01",
  "schema_version": 1,
  "decision_sha256": "<64 lowercase hex>",
  "prompt_sha256": "<64 lowercase hex>",
  "policy_snapshot": {"tier": "focused", "engines": ["codex", "opus"], "evidence_checks": [], "acceptance_after": []},
  "engine_reports": [{"engine": "codex", "path": "research/topics/.../raw/codex.md", "sha256": "<64 lowercase hex>", "identity": {"actor": "unique worker", "model": "resolved model", "family": "openai"}}],
  "evidence_checks": [],
  "synthesis": {"actor": "fresh worker", "model": "resolved model", "family": "anthropic"},
  "audits": [{"kind": "empirical", "path": "research/topics/.../audit-codex.md", "sha256": "<64 lowercase hex>", "identity": {"actor": "empirical-auditor", "model": "resolved model", "family": "openai"}, "decision_sha256": "<64 lowercase hex>", "verdict": "approve", "unresolved_findings": []}, {"kind": "judgment", "path": "research/topics/.../audit-fable.md", "sha256": "<64 lowercase hex>", "identity": {"actor": "judgment-auditor", "model": "resolved model", "family": "anthropic"}, "decision_sha256": "<64 lowercase hex>", "verdict": "approve", "unresolved_findings": []}],
  "empirical": {"argv": ["cargo", "test"], "cwd": "<recorded working directory>", "toolchain": "rustc ...; OS ...", "output_log": "research/topics/.../evidence/command.log", "output_sha256": "<64 lowercase hex>", "exit_code": 0, "executed_by": {"actor": "empirical-auditor", "model": "resolved model", "family": "openai"}},
  "parameters": {"consumed": {}, "fixed": {}},
  "prerequisites": {"research": {}, "acceptance_after": {}},
  "reverify": "event or date",
  "engines": "non-empty synthesis disagreement record",
  "principles": "non-empty selected-principles record"
}
```

Each report and evidence check names an engine in the current policy order;
the Light Terra evidence check is separate from the Codex research report.
`path` is a repository-confined relative path. Its SHA-256 must match the file
bytes. Each identity records a non-empty `actor`, `model`, and `family`.

`synthesis.actor` differs from every raw producer actor. A Light evidence
checker is fresh: its actor differs from all raw producers. Each audit is bound
to the current `decision_sha256`, has verdict `approve`, and has an empty
`unresolved_findings` array. The empirical audit hashes exactly
`audit-codex.md`; the judgment audit hashes exactly `audit-fable.md`. Neither
auditor may be a raw producer, an evidence checker, or the synthesizer. The two
auditors have different actors and different model families. The empirical
executor's family differs from the synthesis family. Its recorded argv,
working directory, toolchain, output log and hash, and integer exit code 0
make rerunning the claimed check possible.

`parameters.fixed` records every current `kind: fixed` registry value, even
when the prompt mentions it only in prose. `parameters.consumed` records every
researched parameter named on the prompt's `- consumes:` line. The current
`DECISION.md ## Parameters` repeats every owned value with `- owns <param> =
<value>` and every fixed or consumed value with `- assumes <param> = <value>`.
Both sets and values must match the current prompt and registry; historical or
fenced declarations cannot satisfy them. `prerequisites.research`
records registry-research prerequisite decision hashes; `prerequisites.acceptance_after`
records publication-prerequisite decision hashes. A prerequisite must still be
resolved, its current `DECISION.md` hash must match, and its own acceptance
bundle is checked recursively. The acceptance-prerequisite keys exactly match
the policy's `acceptance_after`. `reverify`, `engines`, and `principles`
preserve the nonempty decision content that reviewers need.

Each audit Markdown file has these one-per-line, outside-fence fields, whose
values must match its `acceptance.json` record exactly:

```text
decision-sha256: <current decision hash>
actor: <auditor actor>
model: <resolved model>
family: openai | anthropic | actual provider composition
verdict: approve
unresolved-findings: none
```

The audit also contains non-metadata analysis and evidence. Repeating a field
is invalid. Codex and Terra records use family `openai`; Opus, synthesis, and
the judgment audit use `anthropic`. Doxa records the actual provider family
composition rather than the label `doxa`. The empirical execution identity is
the empirical auditor identity, because that audit is the recorded rerun.

## Answer and decision history

Raw answers must have the template's H3 fields in exact order, with a nonempty
body for each. A heading inside a fenced code block does not satisfy a field.
Bundles have `### Members`; each named `#### member` contains the crate answer
shape as H5 headings in this exact order: `Landscape`, `Principles and
implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`,
`Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`,
`Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`,
`Confidence & re-verify trigger`, and `Sources`.

`DECISION.md` history is append-only. The validator assesses the current entry
before its dated historical entries. A reversal appends a new dated current
entry and puts the older entry below `## Supersedes`; headings in fenced code
are ignored here as well. The current `## Decision` includes a nonempty
`### Principles and implementation` and the exact `re-verify: <value>` that
matches `acceptance.json`.

Both backtick and tilde fences are recognized with their actual delimiter
lengths. Empty code fences do not count as answer content. Every bundle member
must be inside `### Members`, with a distinct nonempty H4 name. Current decision
fields and parameter declarations are assessed before `## Supersedes`; an old
entry cannot supply a missing current field.

`check-research-tree.sh` now delegates through the same read lock. The original
Bash structural checks live in `scripts/check-research-tree-core.sh`; the public
wrapper runs that core and the strict Python checks as one coordinated read.
Both readers refuse a pending publication journal until explicit recovery.
