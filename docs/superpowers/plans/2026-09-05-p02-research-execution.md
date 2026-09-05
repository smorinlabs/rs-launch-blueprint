# P02 Research Execution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every one of the 84 research items in `research/CLAUDE.md` with an audited `DECISION.md`, published through the durable runner, so `docs/port/PARAMETERS.md` is fully valued and `scripts/check-research-tree.sh --require-owner-review` passes with every index row `resolved`.

**Architecture:** One task per research item, executed by role-separated fresh subagents (research workers per engine, a synthesizer, an empirical auditor and a judgment auditor) whose independence the runbook mandates; the controller performs only admission, wrapper/runner commands, packaging and commits. Task 1 adds the packaging tool that turns a completed run directory into a validated publication manifest. Items are admitted in dependency order (`queue list`) and run in parallel up to the capacity limits.

**Tech Stack:** `scripts/research_runner.py` (durable state and publication), `scripts/research_validation.py` and `scripts/check-answer-shape.sh` (evidence validation), `scripts/doxa_no_retry.py` with `docs/planning/p02/doxa-pilot.config.toml` (paid Doxa), `codex exec` (OpenAI-family workers), the Agent tool (`opus` research, `fable` synthesis and judgment), Python 3 unittest for the packaging tool.

**Spec:** `research/RUNBOOK.md` (execution contract), `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` §2, §11 and §13, `docs/planning/p02/acceptance-schema.md` (evidence schema), `docs/planning/p02/runner-guide.md` (runner commands), `docs/planning/p02/APPROVAL.md` (authorizations), `docs/superpowers/plans/p02-roles/*.md` (role prompts).

## Global Constraints

- Tiers and engines come from `research/EXECUTION.json`: Light = `["codex"]` research plus a fresh Terra evidence check; Focused = `["codex", "opus"]`; Deep = `["codex", "opus", "doxa"]`; the R38 pilot uses all three engines despite its Focused tier.
- Actor independence (acceptance schema): the synthesizer produced no raw report; each auditor is neither a raw producer, an evidence checker nor the synthesizer; the two auditors have different actors and different model families; the empirical executor's family differs from the synthesis family; a Light evidence checker's actor differs from all raw producers.
- Identity record: Codex workers record the CLI header `model:` line from their transcript (never the model's self-description); Claude subagents record the model ID from their own system prompt together with the CLI probe mapping (`opus` = `claude-opus-5`, `fable` = `claude-fable-5-1`, `docs/planning/p02/probes/`). Families: Codex/Terra/Luna `openai`; Opus, synthesis and judgment audit `anthropic`; Doxa records its actual provider composition, e.g. `openai+perplexity+google`.
- Fixed parameters, quoted from `docs/port/PARAMETERS.md`: `msrv-policy` = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; `rust-edition` = `2024`; `target-os-matrix` = `ubuntu-latest, macos-latest`; `license` = `MIT OR Apache-2.0`. Windows is informative only. The required web example uses OpenTelemetry; feature selection must not make it optional.
- Capacity: at most three Claude subagents active at once (the controller is the fourth Claude call); Codex and Doxa jobs run out of process and do not count; initially one empirical build at a time; stop new admissions when two completed items await acceptance review.
- Paid execution: only through `/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml` (one create attempt per provider, no automatic resubmission); batch `B0-R38` ceiling USD 40; remaining Deep operations share a blanket ceiling of USD 300 in total; authorization reference `OWNER-2026-09-05-P02-EXEC`; record every operation ID immediately with `run submitted`, or `run unknown` when an ID was not returned; never resubmit because a caller timed out.
- Unattended `codex exec` always runs with `< /dev/null`, `-c 'approval_policy="never"'`, `--sandbox workspace-write -c 'sandbox_workspace_write.network_access=true'`, `-C <run directory>`; the plain transcript (not `--json`) is saved so the header identifies the model.
- Raw answers must pass `scripts/check-answer-shape.sh <file> <crate|pattern|bundle> [override]` before synthesis; cosmetic defects are normalized into a separate file that links to the original; originals are never overwritten.
- `DECISION.md` has exactly the H2 sections `## Decision` (with `### Principles and implementation` and a final `re-verify: <value>` line), `## Parameters` (`- owns <param> = <value>` for every owned parameter; `- assumes <param> = <value>` for every fixed and consumed parameter), `## Empirical check` (toolchain, command, working directory, observed output of a check that actually ran), `## Engines`; `## Supersedes` only for a reversal.
- Audit files begin with the one-per-line fields `decision-sha256`, `actor`, `model`, `family`, `verdict`, `unresolved-findings` exactly once each, outside code fences; acceptance requires both verdicts `approve` with `unresolved-findings: none`.
- Publication happens only through `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py publication apply --file <manifest> --staged-dir <dir>`; nothing under `research/topics/*/` except `prompts/` is edited by hand; after each published item the controller commits with a Conventional Commits subject and the session trailer.
- `CONFLICT:` lines follow runbook §4 (consumer stays in progress, owner reopened, registry and owner revision published together); `BASELINE-REVIEW:` lines are adjudicated by the controller and recorded in `docs/port/BASELINE-REVIEW.md`.
- Never edit `docs/port/COMMONALITY.md`, `research/CLAUDE.md` or `docs/port/PARAMETERS.md` outside a publication; the runner's writer lock is the only serialization of those files.

---

### Task 1: Packaging tool for run directories

**Files:**
- Create: `scripts/research_package.py`
- Test: `scripts/test-research-package.py`
- Reference (read, do not modify): `scripts/research_runner.py` (functions `sha`, `topic_dir`, `prompt_path`, `research_prereqs`, `index_statuses`, `publication apply` manifest handling around line 375), `scripts/research_validation.py` (`validate_topic`, `_parse_parameters`), `scripts/test-research-runner.py` (`make_fixture`, `accept_fixture`, `make_manifest` at lines 80–150 show a complete GREEN acceptance bundle), `docs/planning/p02/acceptance-schema.md`, `docs/planning/p02/runner-guide.md`.

**Interfaces:**
- Consumes: a prepared run directory `research/runs/<ITEM>/<RUN_ID>/` containing `inputs/prompt.md`, `raw/<engine>.md` (optionally `raw/<engine>.normalized.md`), `review/DECISION.md`, `review/audit-codex.md`, `review/audit-fable.md`, `review/evidence/*.log`, and `review/identities.json` with this exact shape:

```json
{
  "engine_reports": {"codex": {"actor": "research-codex-<run>", "model": "gpt-5.6-terra", "family": "openai", "file": "raw/codex.md"},
                     "opus": {"actor": "research-opus-<run>", "model": "claude-opus-5", "family": "anthropic", "file": "raw/opus.md"},
                     "doxa": {"actor": "research-doxa-<run>", "model": "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026", "family": "openai+perplexity+google", "file": "raw/doxa.md"}},
  "evidence_checks": {"terra": {"actor": "evidence-terra-<run>", "model": "gpt-5.6-terra", "family": "openai", "file": "raw/evidence-terra.md"}},
  "synthesis": {"actor": "synth-fable-<run>", "model": "claude-fable-5-1", "family": "anthropic"},
  "audits": {"empirical": {"actor": "audit-codex-<run>", "model": "gpt-5.6-terra", "family": "openai", "file": "review/audit-codex.md"},
             "judgment": {"actor": "audit-fable-<run>", "model": "claude-fable-5-1", "family": "anthropic", "file": "review/audit-fable.md"}},
  "empirical": {"argv": ["cargo", "test"], "cwd": "research/runs/<ITEM>/<RUN_ID>/review/empirical-audit/fixture", "toolchain": "rustc 1.98.0; cargo 1.98.0; macOS 15", "output_log": "review/evidence/audit-<name>.log", "exit_code": 0}
}
```
  Only the engines present in the item's policy appear under `engine_reports`; `evidence_checks` is empty except for Light items.
- Produces: `research_package.py build --root <repo> --item <ITEM> --run-id <RUN_ID> --staged-dir <dir> [--json]`, which writes into `<dir>` a repository-relative staged tree containing `research/topics/<topic>/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md` (one per engine report, copied from the normalized file when present, else the original), `evidence/<RUN_ID>-<basename>.log` for every log under `review/evidence/`, `research/CLAUDE.md` with the item's status cell changed from `open` or `in-progress` to `resolved`, `docs/port/PARAMETERS.md` with every `- owns <param> = <value>` line of the decision copied into the `value` column of that parameter's row (owner column unchanged), and `<dir>/manifest.json` of the runner's shape (`item`, `run_id`, `dependency_hashes: {}`, `changes: [{target, expected_sha256 | "missing", staged}]`) listing every staged file whose bytes differ from the repository's current file. On success it prints one JSON object `{"ok": true, "result": {"manifest": ..., "changes": N, "acceptance_sha256": ...}}`; on any error one JSON error object on stderr and exit 1 (usage errors exit 2), using `scripts/research_cli.py` like the other tools.
- `acceptance.json` follows `docs/planning/p02/acceptance-schema.md` exactly: `decision_sha256` and `prompt_sha256` from the staged decision and the run's `inputs/prompt.md` (refuse if that copy differs from the current prompt); `policy_snapshot` from `research/EXECUTION.json`; `engine_reports` in policy engine order with the staged raw path, its sha256 and the identity; `evidence_checks` likewise; `synthesis`; `audits` (kind `empirical` bound to `audit-codex.md`, kind `judgment` bound to `audit-fable.md`, each with the staged path, sha256, identity, `decision_sha256`, `verdict` and `unresolved_findings` parsed from the audit file's fields, refusing a verdict other than `approve` or findings other than `none`); `empirical` from `identities.json` with `output_log` rewritten to the staged evidence path, its sha256, and `executed_by` = the empirical audit identity; `parameters.fixed` = every `kind: fixed` registry value, `parameters.consumed` = for every `R##` on the prompt's `- consumes:` line, that owner's `- owns` values from its published `DECISION.md`; `prerequisites.research` = `{R##: sha256 of its DECISION.md}` for research prerequisites (`consumes` plus the non-owner related-to-owner rule, reuse `research_runner.research_prereqs`), `prerequisites.acceptance_after` likewise for the policy's list; `reverify` = the value after `re-verify:` in `## Decision`; `engines` = the text of `## Engines`; `principles` = the text of `### Principles and implementation`.

- [ ] **Step 1: Write the failing tests**

Create `scripts/test-research-package.py` (unittest, run offline with `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/test-research-package.py`). Build a temporary repository copy the way `scripts/test-research-runner.py` does (`make_fixture`-style: copy `research/`, `docs/port/`, `scripts/`, `docs/superpowers/specs/` of the real tree into a temp dir, excluding `research/runs`), prepare a run for `R38` with the runner's `run prepare`, then write into that run directory synthetic but shape-valid raws (reuse the field lists `validator.CRATE_FIELDS`), a decision with the four H2s and `re-verify: fixture`, two approving audits whose `decision-sha256` matches, one evidence log, and an `identities.json` as specified. Tests:

```python
def test_build_writes_validating_acceptance_and_manifest(self):
    result = self.build()              # runs research_package.py build --json
    self.assertTrue(result["ok"])
    staged = self.staged
    acceptance = json.loads((staged / "research/topics/38-commit-message-linter/acceptance.json").read_text())
    self.assertEqual(acceptance["item"], "R38")
    self.assertEqual(acceptance["decision_sha256"], sha(staged / "research/topics/38-commit-message-linter/DECISION.md"))
    self.assertEqual([r["engine"] for r in acceptance["engine_reports"]], ["codex", "opus", "doxa"])
    self.assertIn("| R38 |", (staged / "research/CLAUDE.md").read_text())
    self.assertIn("| resolved |", [l for l in (staged / "research/CLAUDE.md").read_text().splitlines() if l.startswith("| R38 |")][0])
    self.assertIn("feat, fix", (staged / "docs/port/PARAMETERS.md").read_text())   # the fixture decision owns commit-message-convention = feat, fix, ...
    manifest = json.loads((staged / "manifest.json").read_text())
    targets = {c["target"] for c in manifest["changes"]}
    self.assertIn("research/topics/38-commit-message-linter/acceptance.json", targets)
    self.assertIn("research/CLAUDE.md", targets)
    self.assertIn("docs/port/PARAMETERS.md", targets)

def test_staged_tree_passes_the_strict_validator(self):
    self.build()
    # copy the staged files over a copy of the fixture tree and run validate_topic
    self.assertEqual(validator.validate_topic(self.overlay(), "R38"), [])

def test_publication_apply_accepts_the_manifest(self):
    self.build()
    result = self.runner("publication", "apply", "--file", str(self.staged / "manifest.json"), "--staged-dir", str(self.staged))
    self.assertTrue(result["ok"], result)
    self.assertEqual(self.runner("run", "status", "R38", "--run-id", self.run_id)["result"]["state"], "published")

def test_refuses_rejecting_audit_and_stale_prompt(self):
    (self.run_dir / "review/audit-fable.md").write_text(self.audit_text(verdict="reject", findings="missing gate"))
    self.assertFalse(self.build(expect_ok=False)["ok"])
    self.restore_audit()
    (self.root / "research/topics/38-commit-message-linter/prompts/commit-message-linter.prompt.md").write_text("changed\n")
    self.assertFalse(self.build(expect_ok=False)["ok"])

def test_light_item_records_evidence_check(self):
    # prepare R22 (Light), raw codex only plus raw/evidence-terra.md and an evidence_checks identity
    acceptance = self.build_light("R22")
    self.assertEqual([e["engine"] for e in acceptance["evidence_checks"]], ["terra"])
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/test-research-package.py`
Expected: FAIL with `No module named research_package` or file-not-found for `scripts/research_package.py`.

- [ ] **Step 3: Implement `scripts/research_package.py`**

Implement `build` exactly as specified in Interfaces: parse `identities.json`; verify the run's `inputs/prompt.md` equals the current prompt; copy raws, decision, audits and logs into the staged tree; parse the audit fields (each field exactly once, outside fences, verdict `approve`, findings `none`); extract `re-verify:`, `## Engines` and `### Principles and implementation` from the decision; compute fixed and consumed parameters and prerequisite hashes with the runner's and validator's helpers (import them with `sys.path` set to `scripts/`); rewrite the index status and the registry value column; write `acceptance.json` and `manifest.json`; emit the JSON contract via `research_cli.py`. Refuse (exit 1, JSON error) when any required file, field, identity or prerequisite decision is missing, when a prerequisite is not `resolved`, or when a verdict is not `approve`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/test-research-package.py`
Expected: `OK` with 5 tests; then run the full existing suite (`scripts/test-check-research-tree.sh`, `scripts/test-research-validation.py`, `scripts/test-research-runner.py`, `scripts/test-research-answer-parser.py`, `scripts/test-research-reader-lock.py`, `scripts/test-derive-port-docs.py`, `scripts/test-doxa-no-retry.py`) and `scripts/check-research-tree.sh --require-owner-review`; all must pass.

- [ ] **Step 5: Document and commit**

Add one paragraph to `docs/planning/p02/runner-guide.md` after the manifest example describing `research_package.py build` and `review/identities.json`, and one line to the checking paragraph of `docs/port/README.md` naming `scripts/test-research-package.py`. Commit:

```bash
git add scripts/research_package.py scripts/test-research-package.py docs/planning/p02/runner-guide.md docs/port/README.md
git commit -m "feat(research): package a completed run into a validated publication manifest"
```


### Task 2: R38 commit-message-linter (crate, focused; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R38/<RUN_ID>/` with `raw/`, `review/`, `operations/` — the pilot run already exists: `research/runs/R38/2026-09-05T151356Z-c46d732f98ed/` (state `ready`)
- Published by the runner only: `research/topics/38-commit-message-linter/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/38-commit-message-linter/prompts/commit-message-linter.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: commit-message-convention
- Produces: a `resolved` index row for R38, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R38 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Already done: `RUN_ID=2026-09-05T151356Z-c46d732f98ed`, `RUN_DIR=research/runs/R38/$RUN_ID`, authorization `OWNER-2026-09-05-P02-EXEC`, budget `USD 40.00 remaining of USD 40.00 for batch B0-R38 (job-count boundary; no automatic retry)`. The pilot is the only item running until it is published.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R38 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R38 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R38 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R38 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R38 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R38 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R38 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R38 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R38 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R38 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R38 (crate, owns: commit-message-convention). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R38. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R38. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R38 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/38-commit-message-linter research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R38/$RUN_ID
git commit -m "feat(research): resolve R38 commit-message-linter"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 3: R01 ports-and-adapters-seam (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R01/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/01-ports-and-adapters-seam/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/01-ports-and-adapters-seam/prompts/ports-and-adapters-seam.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: http-transport-injection-seam
- Produces: a `resolved` index row for R01, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R01 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R01` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R01 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R01/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R01 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R01 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R01 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R01 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R01 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R01 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R01 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R01 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R01 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R01 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R01 (bundle, owns: http-transport-injection-seam). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R01. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R01. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R01 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/01-ports-and-adapters-seam research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R01/$RUN_ID
git commit -m "feat(research): resolve R01 ports-and-adapters-seam"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 4: R42 dev-toolchain-provisioning (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R42/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/42-dev-toolchain-provisioning/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/42-dev-toolchain-provisioning/prompts/dev-toolchain-provisioning.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: package-manager-invocation
- Produces: a `resolved` index row for R42, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R42 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R42` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R42 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R42/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R42 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R42 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R42 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R42 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R42 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R42 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R42 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R42 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R42 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R42 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R42 (bundle, owns: package-manager-invocation). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R42. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R42. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R42 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/42-dev-toolchain-provisioning research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R42/$RUN_ID
git commit -m "feat(research): resolve R42 dev-toolchain-provisioning"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 5: R49 build-target-declaration (crate, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R49/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/49-build-target-declaration/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/49-build-target-declaration/prompts/build-target-declaration.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: build-tool-output-shape
- Produces: a `resolved` index row for R49, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R49 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R49` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R49 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R49/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R49 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R49 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R49 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R49 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R49 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R49 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R49 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R49 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R49 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R49 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R49 (crate, owns: build-tool-output-shape). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R49. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R49. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R49 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/49-build-target-declaration research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R49/$RUN_ID
git commit -m "feat(research): resolve R49 build-target-declaration"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 6: R67 error-and-exit-code-contract (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R67/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/67-error-and-exit-code-contract/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/67-error-and-exit-code-contract/prompts/error-and-exit-code-contract.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: error-taxonomy-exit-codes
- Produces: a `resolved` index row for R67, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R67 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R67` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R67 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R67/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R67 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R67 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R67 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R67 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R67 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R67 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R67 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R67 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R67 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R67 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R67 (bundle, owns: error-taxonomy-exit-codes). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R67. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R67. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R67 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/67-error-and-exit-code-contract research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R67/$RUN_ID
git commit -m "feat(research): resolve R67 error-and-exit-code-contract"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 7: R04 public-api-surface-enforcement (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R04/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/04-public-api-surface-enforcement/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/04-public-api-surface-enforcement/prompts/public-api-surface-enforcement.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R04, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R04 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R04` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R04 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R04/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R04 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R04 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R04 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R04 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R04 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R04 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R04 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R04. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R04. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R04 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/04-public-api-surface-enforcement research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R04/$RUN_ID
git commit -m "feat(research): resolve R04 public-api-surface-enforcement"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 8: R06 unsafe-code-policy (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R06/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/06-unsafe-code-policy/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/06-unsafe-code-policy/prompts/unsafe-code-policy.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R06, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R06 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R06` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R06 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R06/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R06 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R06 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R06 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R06 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R06 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R06 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R06 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R06. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R06. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R06 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/06-unsafe-code-policy research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R06/$RUN_ID
git commit -m "feat(research): resolve R06 unsafe-code-policy"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 9: R07 contributors-bot-trigger-cadence (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R07/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/07-contributors-bot-trigger-cadence/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/07-contributors-bot-trigger-cadence/prompts/contributors-bot-trigger-cadence.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R07, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R07 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R07` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R07 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R07/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R07 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R07 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R07 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R07 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R07 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R07 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R07 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R07. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R07. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R07 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/07-contributors-bot-trigger-cadence research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R07/$RUN_ID
git commit -m "feat(research): resolve R07 contributors-bot-trigger-cadence"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 10: R15 template-drift-receipt-guard (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R15/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/15-template-drift-receipt-guard/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/15-template-drift-receipt-guard/prompts/template-drift-receipt-guard.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R15, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R15 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R15` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R15 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R15/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R15 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R15 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R15 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R15 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R15 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R15 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R15 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R15. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R15. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R15 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/15-template-drift-receipt-guard research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R15/$RUN_ID
git commit -m "feat(research): resolve R15 template-drift-receipt-guard"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 11: R16 codeql-config-customization (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R16/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/16-codeql-config-customization/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/16-codeql-config-customization/prompts/codeql-config-customization.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R16, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R16 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R16` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R16 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R16/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R16 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R16 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R16 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R16 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R16 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R16 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R16 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R16. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R16. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R16 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/16-codeql-config-customization research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R16/$RUN_ID
git commit -m "feat(research): resolve R16 codeql-config-customization"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 12: R17 secret-scanning-ci-workflow (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R17/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/17-secret-scanning-ci-workflow/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/17-secret-scanning-ci-workflow/prompts/secret-scanning-ci-workflow.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R17, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R17 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R17` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R17 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R17/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R17 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R17 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R17 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R17 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R17 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R17 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R17 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R17. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R17. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R17 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/17-secret-scanning-ci-workflow research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R17/$RUN_ID
git commit -m "feat(research): resolve R17 secret-scanning-ci-workflow"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 13: R18 ai-assisted-review-workflows (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R18/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/18-ai-assisted-review-workflows/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/18-ai-assisted-review-workflows/prompts/ai-assisted-review-workflows.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R18, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R18 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R18` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R18 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R18/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R18 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R18 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R18 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R18 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R18 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R18 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R18 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R18 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R18 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R18 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R18 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R18. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R18. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R18 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/18-ai-assisted-review-workflows research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R18/$RUN_ID
git commit -m "feat(research): resolve R18 ai-assisted-review-workflows"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 14: R19 dependabot-config-shape (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R19/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/19-dependabot-config-shape/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/19-dependabot-config-shape/prompts/dependabot-config-shape.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R19, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R19 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R19` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R19 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R19/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R19 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R19 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R19 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R19 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R19 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R19 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R19 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R19. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R19. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R19 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/19-dependabot-config-shape research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R19/$RUN_ID
git commit -m "feat(research): resolve R19 dependabot-config-shape"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 15: R20 third-party-action-pinning-policy (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R20/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/20-third-party-action-pinning-policy/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/20-third-party-action-pinning-policy/prompts/third-party-action-pinning-policy.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R20, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R20 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R20` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R20 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R20/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R20 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R20 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R20 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R20 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R20 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R20 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R20 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R20. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R20. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R20 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/20-third-party-action-pinning-policy research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R20/$RUN_ID
git commit -m "feat(research): resolve R20 third-party-action-pinning-policy"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 16: R21 contributors-bot-credential-source (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R21/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/21-contributors-bot-credential-source/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/21-contributors-bot-credential-source/prompts/contributors-bot-credential-source.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R21, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R21 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R21` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R21 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R21/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R21 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R21 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R21 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R21 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R21 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R21 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R21 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R21. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R21. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R21 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/21-contributors-bot-credential-source research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R21/$RUN_ID
git commit -m "feat(research): resolve R21 contributors-bot-credential-source"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 17: R23 lockfile-version-sync (pattern, light; engines codex; evidence check terra)

**Files:**
- Run directory (create via the runner): `research/runs/R23/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/23-lockfile-version-sync/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/23-lockfile-version-sync/prompts/lockfile-version-sync.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R23, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R23 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R23` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R23 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R23/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R23 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-luna
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-luna -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R23 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R23 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R23 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-luna
```

Evidence check (Light): after `raw/codex.md` passes the shape check, run a fresh `/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec -m gpt-5.6-terra` in $RUN_DIR with the same flags, prompt: "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/evidence-check.md, then inputs/prompt.md and raw/codex.md. Actor id evidence-terra-$RUN_ID. Write raw/evidence-terra.md and nothing else." A `defective` verdict sends the defects back to the research worker (resume the same Codex session with `codex exec resume`, or a fresh worker with the defects listed) before synthesis.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R23 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R23. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R23. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R23 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/23-lockfile-version-sync research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R23/$RUN_ID
git commit -m "feat(research): resolve R23 lockfile-version-sync"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 18: R25 semver-bump-strategy (pattern, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R25/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/25-semver-bump-strategy/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/25-semver-bump-strategy/prompts/semver-bump-strategy.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R25, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R25 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R25` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R25 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R25/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R25 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R25 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R25 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R25 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R25 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R25 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R25 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R25 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R25 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R25 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R25 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R25. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R25. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R25 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/25-semver-bump-strategy research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R25/$RUN_ID
git commit -m "feat(research): resolve R25 semver-bump-strategy"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 19: R26 packed-artifact-content-guard (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R26/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/26-packed-artifact-content-guard/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/26-packed-artifact-content-guard/prompts/packed-artifact-content-guard.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R26, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R26 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R26` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R26 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R26/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R26 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R26 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R26 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R26 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R26 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R26 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R26 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R26. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R26. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R26 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/26-packed-artifact-content-guard research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R26/$RUN_ID
git commit -m "feat(research): resolve R26 packed-artifact-content-guard"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 20: R33 property-and-snapshot-testing (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R33/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/33-property-and-snapshot-testing/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/33-property-and-snapshot-testing/prompts/property-and-snapshot-testing.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R33, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R33 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R33` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R33 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R33/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R33 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R33 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R33 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R33 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R33 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R33 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R33 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R33. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R33. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R33 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/33-property-and-snapshot-testing research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R33/$RUN_ID
git commit -m "feat(research): resolve R33 property-and-snapshot-testing"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 21: R34 scheduled-freshness-lanes (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R34/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/34-scheduled-freshness-lanes/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/34-scheduled-freshness-lanes/prompts/scheduled-freshness-lanes.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R34, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R34 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R34` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R34 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R34/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R34 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R34 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R34 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R34 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R34 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R34 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R34 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R34. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R34. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R34 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/34-scheduled-freshness-lanes research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R34/$RUN_ID
git commit -m "feat(research): resolve R34 scheduled-freshness-lanes"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 22: R41 lockfile-freshness-check (pattern, light; engines codex; evidence check terra)

**Files:**
- Run directory (create via the runner): `research/runs/R41/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/41-lockfile-freshness-check/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/41-lockfile-freshness-check/prompts/lockfile-freshness-check.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R41, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R41 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R41` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R41 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R41/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R41 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-luna
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-luna -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R41 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R41 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R41 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-luna
```

Evidence check (Light): after `raw/codex.md` passes the shape check, run a fresh `/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec -m gpt-5.6-terra` in $RUN_DIR with the same flags, prompt: "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/evidence-check.md, then inputs/prompt.md and raw/codex.md. Actor id evidence-terra-$RUN_ID. Write raw/evidence-terra.md and nothing else." A `defective` verdict sends the defects back to the research worker (resume the same Codex session with `codex exec resume`, or a fresh worker with the defects listed) before synthesis.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R41 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R41. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R41. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R41 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/41-lockfile-freshness-check research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R41/$RUN_ID
git commit -m "feat(research): resolve R41 lockfile-freshness-check"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 23: R43 ai-assistant-repo-furniture (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R43/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/43-ai-assistant-repo-furniture/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/43-ai-assistant-repo-furniture/prompts/ai-assistant-repo-furniture.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R43, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R43 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R43` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R43 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R43/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R43 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R43 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R43 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R43 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R43 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R43 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R43 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R43. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R43. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R43 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/43-ai-assistant-repo-furniture research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R43/$RUN_ID
git commit -m "feat(research): resolve R43 ai-assistant-repo-furniture"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 24: R45 pr-comment-bot-trigger-block (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R45/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/45-pr-comment-bot-trigger-block/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/45-pr-comment-bot-trigger-block/prompts/pr-comment-bot-trigger-block.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R45, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R45 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R45` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R45 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R45/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R45 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R45 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R45 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R45 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R45 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R45 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R45 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R45. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R45. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R45 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/45-pr-comment-bot-trigger-block research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R45/$RUN_ID
git commit -m "feat(research): resolve R45 pr-comment-bot-trigger-block"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 25: R46 per-file-license-header (pattern, light; engines codex; evidence check terra)

**Files:**
- Run directory (create via the runner): `research/runs/R46/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/46-per-file-license-header/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/46-per-file-license-header/prompts/per-file-license-header.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R46, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R46 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R46` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R46 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R46/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R46 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-luna
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-luna -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R46 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R46 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R46 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-luna
```

Evidence check (Light): after `raw/codex.md` passes the shape check, run a fresh `/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec -m gpt-5.6-terra` in $RUN_DIR with the same flags, prompt: "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/evidence-check.md, then inputs/prompt.md and raw/codex.md. Actor id evidence-terra-$RUN_ID. Write raw/evidence-terra.md and nothing else." A `defective` verdict sends the defects back to the research worker (resume the same Codex session with `codex exec resume`, or a fresh worker with the defects listed) before synthesis.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R46 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R46. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R46. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R46 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/46-per-file-license-header research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R46/$RUN_ID
git commit -m "feat(research): resolve R46 per-file-license-header"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 26: R47 contributors-recipe-mode (pattern, light; engines codex; evidence check terra)

**Files:**
- Run directory (create via the runner): `research/runs/R47/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/47-contributors-recipe-mode/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/47-contributors-recipe-mode/prompts/contributors-recipe-mode.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R47, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R47 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R47` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R47 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R47/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R47 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-luna
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-luna -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R47 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R47 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R47 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-luna
```

Evidence check (Light): after `raw/codex.md` passes the shape check, run a fresh `/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec -m gpt-5.6-terra` in $RUN_DIR with the same flags, prompt: "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/evidence-check.md, then inputs/prompt.md and raw/codex.md. Actor id evidence-terra-$RUN_ID. Write raw/evidence-terra.md and nothing else." A `defective` verdict sends the defects back to the research worker (resume the same Codex session with `codex exec resume`, or a fresh worker with the defects listed) before synthesis.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R47 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R47. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R47. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R47 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/47-contributors-recipe-mode research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R47/$RUN_ID
git commit -m "feat(research): resolve R47 contributors-recipe-mode"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 27: R60 cli-parsing-framework (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R60/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/60-cli-parsing-framework/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/60-cli-parsing-framework/prompts/cli-parsing-framework.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R60, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R60 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R60` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R60 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R60/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R60 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R60 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R60 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R60 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R60 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R60 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R60 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R60 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R60 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R60 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R60 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R60. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R60. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R60 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/60-cli-parsing-framework research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R60/$RUN_ID
git commit -m "feat(research): resolve R60 cli-parsing-framework"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 28: R63 progress-spinner (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R63/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/63-progress-spinner/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/63-progress-spinner/prompts/progress-spinner.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R63, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R63 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R63` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R63 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R63/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R63 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R63 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R63 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R63 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R63 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R63 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R63 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R63. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R63. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R63 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/63-progress-spinner research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R63/$RUN_ID
git commit -m "feat(research): resolve R63 progress-spinner"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 29: R64 pager-integration (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R64/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/64-pager-integration/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/64-pager-integration/prompts/pager-integration.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R64, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R64 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R64` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R64 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R64/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R64 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R64 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R64 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R64 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R64 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R64 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R64 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R64. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R64. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R64 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/64-pager-integration research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R64/$RUN_ID
git commit -m "feat(research): resolve R64 pager-integration"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 30: R65 color-enablement-chain (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R65/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/65-color-enablement-chain/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/65-color-enablement-chain/prompts/color-enablement-chain.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R65, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R65 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R65` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R65 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R65/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R65 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R65 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R65 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R65 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R65 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R65 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R65 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R65. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R65. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R65 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/65-color-enablement-chain research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R65/$RUN_ID
git commit -m "feat(research): resolve R65 color-enablement-chain"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 31: R66 output-format-surface (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R66/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/66-output-format-surface/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/66-output-format-surface/prompts/output-format-surface.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R66, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R66 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R66` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R66 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R66/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R66 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R66 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R66 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R66 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R66 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R66 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R66 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R66 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R66 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R66 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R66 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R66. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R66. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R66 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/66-output-format-surface research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R66/$RUN_ID
git commit -m "feat(research): resolve R66 output-format-surface"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 32: R81 docs-delivery-model (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R81/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/81-docs-delivery-model/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/81-docs-delivery-model/prompts/docs-delivery-model.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R81, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R81 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R81` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R81 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R81/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R81 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R81 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R81 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R81 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R81 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R81 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R81 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R81. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R81. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R81 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/81-docs-delivery-model research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R81/$RUN_ID
git commit -m "feat(research): resolve R81 docs-delivery-model"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 33: R85 rich-terminal-row-niceties (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R85/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/85-rich-terminal-row-niceties/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/85-rich-terminal-row-niceties/prompts/rich-terminal-row-niceties.prompt.md`

**Interfaces:**
- Consumes: research prerequisites none (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R85, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R85 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R85` is listed under `ready` (all of no prerequisites resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R85 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R85/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R85 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R85 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R85 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R85 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R85 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R85 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R85 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: none. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R85. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R85. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R85 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/85-rich-terminal-row-niceties research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R85/$RUN_ID
git commit -m "feat(research): resolve R85 rich-terminal-row-niceties"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 34: R69 web-framework-stack (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R69/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/69-web-framework-stack/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/69-web-framework-stack/prompts/web-framework-stack.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R01 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: web-extra-surface
- Produces: a `resolved` index row for R69, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R69 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R69` is listed under `ready` (all of R01 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R69 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R69/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R69 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R69 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R69 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R69 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R69 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R69 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R69 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R69 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R69 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R69 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R69 (bundle, owns: web-extra-surface). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R01. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R69. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R69. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R69 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/69-web-framework-stack research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R69/$RUN_ID
git commit -m "feat(research): resolve R69 web-framework-stack"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 35: R02 crate-boundary-enforcement (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R02/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/02-crate-boundary-enforcement/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/02-crate-boundary-enforcement/prompts/crate-boundary-enforcement.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R01 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R02, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R02 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R02` is listed under `ready` (all of R01 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R02 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R02/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R02 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R02 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R02 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R02 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R02 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R02 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R02 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R02 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R02 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R02 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R02 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R01. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R02. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R02. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R02 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/02-crate-boundary-enforcement research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R02/$RUN_ID
git commit -m "feat(research): resolve R02 crate-boundary-enforcement"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 36: R03 port-absence-vs-failure-contract (pattern, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R03/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/03-port-absence-vs-failure-contract/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/03-port-absence-vs-failure-contract/prompts/port-absence-vs-failure-contract.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R01, R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R03, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R03 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R03` is listed under `ready` (all of R01, R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R03 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R03/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R03 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R03 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R03 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R03 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R03 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R03 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R03 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R03 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R03 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R03 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R03 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R01, research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R03. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R03. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R03 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/03-port-absence-vs-failure-contract research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R03/$RUN_ID
git commit -m "feat(research): resolve R03 port-absence-vs-failure-contract"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 37: R05 sync-async-execution-model (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R05/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/05-sync-async-execution-model/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/05-sync-async-execution-model/prompts/sync-async-execution-model.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R01 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R05, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R05 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R05` is listed under `ready` (all of R01 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R05 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R05/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R05 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R05 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R05 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R05 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R05 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R05 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R05 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R05 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R05 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R05 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R05 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R01. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R05. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R05. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R05 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/05-sync-async-execution-model research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R05/$RUN_ID
git commit -m "feat(research): resolve R05 sync-async-execution-model"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 38: R10 dependency-cache-action (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R10/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/10-dependency-cache-action/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/10-dependency-cache-action/prompts/dependency-cache-action.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R42 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R10, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R10 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R10` is listed under `ready` (all of R42 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R10 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R10/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R10 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R10 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R10 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R10 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R10 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R10 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R10 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R42. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R10. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R10. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R10 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/10-dependency-cache-action research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R10/$RUN_ID
git commit -m "feat(research): resolve R10 dependency-cache-action"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 39: R22 runtime-version-accessor (pattern, light; engines codex; evidence check terra)

**Files:**
- Run directory (create via the runner): `research/runs/R22/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/22-runtime-version-accessor/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/22-runtime-version-accessor/prompts/runtime-version-accessor.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R49 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R22, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R22 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R22` is listed under `ready` (all of R49 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R22 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R22/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R22 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-luna
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-luna -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R22 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R22 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R22 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-luna
```

Evidence check (Light): after `raw/codex.md` passes the shape check, run a fresh `/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec -m gpt-5.6-terra` in $RUN_DIR with the same flags, prompt: "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/evidence-check.md, then inputs/prompt.md and raw/codex.md. Actor id evidence-terra-$RUN_ID. Write raw/evidence-terra.md and nothing else." A `defective` verdict sends the defects back to the research worker (resume the same Codex session with `codex exec resume`, or a fresh worker with the defects listed) before synthesis.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R22 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R49. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R22. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R22. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R22 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/22-runtime-version-accessor research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R22/$RUN_ID
git commit -m "feat(research): resolve R22 runtime-version-accessor"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 40: R24 changelog-section-mapping (pattern, light; engines codex; evidence check terra)

**Files:**
- Run directory (create via the runner): `research/runs/R24/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/24-changelog-section-mapping/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/24-changelog-section-mapping/prompts/changelog-section-mapping.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R38 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R24, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R24 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R24` is listed under `ready` (all of R38 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R24 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R24/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R24 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-luna
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-luna -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R24 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R24 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R24 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-luna
```

Evidence check (Light): after `raw/codex.md` passes the shape check, run a fresh `/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec -m gpt-5.6-terra` in $RUN_DIR with the same flags, prompt: "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/evidence-check.md, then inputs/prompt.md and raw/codex.md. Actor id evidence-terra-$RUN_ID. Write raw/evidence-terra.md and nothing else." A `defective` verdict sends the defects back to the research worker (resume the same Codex session with `codex exec resume`, or a fresh worker with the defects listed) before synthesis.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R24 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R38. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R24. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R24. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R24 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/24-changelog-section-mapping research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R24/$RUN_ID
git commit -m "feat(research): resolve R24 changelog-section-mapping"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 41: R44 devcontainer-environment (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R44/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/44-devcontainer-environment/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/44-devcontainer-environment/prompts/devcontainer-environment.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R42 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R44, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R44 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R44` is listed under `ready` (all of R42 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R44 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R44/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R44 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R44 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R44 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R44 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R44 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R44 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R44 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R42. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R44. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R44. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R44 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/44-devcontainer-environment research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R44/$RUN_ID
git commit -m "feat(research): resolve R44 devcontainer-environment"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 42: R48 mocking-crates (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R48/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/48-mocking-crates/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/48-mocking-crates/prompts/mocking-crates.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R01 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R48, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R48 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R48` is listed under `ready` (all of R01 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R48 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R48/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R48 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R48 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R48 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R48 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R48 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R48 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R48 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R01. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R48. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R48. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R48 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/48-mocking-crates research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R48/$RUN_ID
git commit -m "feat(research): resolve R48 mocking-crates"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 43: R50 install-smoke-test (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R50/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/50-install-smoke-test/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/50-install-smoke-test/prompts/install-smoke-test.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R49 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R50, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R50 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R50` is listed under `ready` (all of R49 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R50 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R50/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R50 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R50 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R50 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R50 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R50 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R50 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R50 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R49. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R50. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R50. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R50 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/50-install-smoke-test research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R50/$RUN_ID
git commit -m "feat(research): resolve R50 install-smoke-test"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 44: R52 toml-crate (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R52/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/52-toml-crate/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/52-toml-crate/prompts/toml-crate.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R52, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R52 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R52` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R52 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R52/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R52 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R52 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R52 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R52 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R52 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R52 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R52 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R52. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R52. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R52 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/52-toml-crate research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R52/$RUN_ID
git commit -m "feat(research): resolve R52 toml-crate"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 45: R53 config-schema-validation (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R53/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/53-config-schema-validation/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/53-config-schema-validation/prompts/config-schema-validation.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R53, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R53 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R53` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R53 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R53/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R53 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R53 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R53 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R53 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R53 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R53 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R53 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R53. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R53. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R53 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/53-config-schema-validation research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R53/$RUN_ID
git commit -m "feat(research): resolve R53 config-schema-validation"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 46: R54 config-discovery-tiers (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R54/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/54-config-discovery-tiers/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/54-config-discovery-tiers/prompts/config-discovery-tiers.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R54, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R54 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R54` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R54 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R54/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R54 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R54 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R54 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R54 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R54 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R54 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R54 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R54 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R54 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R54 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R54 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R54. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R54. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R54 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/54-config-discovery-tiers research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R54/$RUN_ID
git commit -m "feat(research): resolve R54 config-discovery-tiers"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 47: R55 config-error-tolerance (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R55/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/55-config-error-tolerance/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/55-config-error-tolerance/prompts/config-error-tolerance.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R55, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R55 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R55` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R55 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R55/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R55 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R55 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R55 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R55 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R55 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R55 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R55 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R55. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R55. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R55 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/55-config-error-tolerance research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R55/$RUN_ID
git commit -m "feat(research): resolve R55 config-error-tolerance"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 48: R56 config-secret-policy (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R56/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/56-config-secret-policy/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/56-config-secret-policy/prompts/config-secret-policy.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R56, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R56 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R56` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R56 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R56/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R56 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R56 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R56 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R56 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R56 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R56 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R56 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R56 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R56 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R56 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R56 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R56. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R56. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R56 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/56-config-secret-policy research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R56/$RUN_ID
git commit -m "feat(research): resolve R56 config-secret-policy"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 49: R57 xdg-directory-set (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R57/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/57-xdg-directory-set/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/57-xdg-directory-set/prompts/xdg-directory-set.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R57, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R57 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R57` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R57 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R57/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R57 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R57 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R57 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R57 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R57 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R57 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R57 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R57. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R57. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R57 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/57-xdg-directory-set research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R57/$RUN_ID
git commit -m "feat(research): resolve R57 xdg-directory-set"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 50: R61 interactive-prompts (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R61/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/61-interactive-prompts/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/61-interactive-prompts/prompts/interactive-prompts.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R61, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R61 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R61` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R61 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R61/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R61 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R61 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R61 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R61 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R61 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R61 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R61 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R61. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R61. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R61 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/61-interactive-prompts research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R61/$RUN_ID
git commit -m "feat(research): resolve R61 interactive-prompts"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 51: R62 clipboard-integration (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R62/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/62-clipboard-integration/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/62-clipboard-integration/prompts/clipboard-integration.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R62, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R62 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R62` is listed under `ready` (all of R67 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R62 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R62/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R62 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R62 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R62 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R62 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R62 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R62 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R62 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R62. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R62. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R62 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/62-clipboard-integration research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R62/$RUN_ID
git commit -m "feat(research): resolve R62 clipboard-integration"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 52: R68 release-binary-artifacts (crate, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R68/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/68-release-binary-artifacts/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/68-release-binary-artifacts/prompts/release-binary-artifacts.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R49 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R68, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R68 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R68` is listed under `ready` (all of R49 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R68 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R68/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R68 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R68 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R68 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R68 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R68 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R68 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R68 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R68 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R68 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R68 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R68 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R49. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R68. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R68. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R68 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/68-release-binary-artifacts research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R68/$RUN_ID
git commit -m "feat(research): resolve R68 release-binary-artifacts"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 53: R11 ci-workflow-job-structure (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R11/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/11-ci-workflow-job-structure/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/11-ci-workflow-job-structure/prompts/ci-workflow-job-structure.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: ci-job-structure
- Produces: a `resolved` index row for R11, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R11 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R11` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R11 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R11/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R11 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R11 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R11 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R11 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R11 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R11 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R11 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R11 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R11 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R11 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R11 (bundle, owns: ci-job-structure). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R11. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R11. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R11 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/11-ci-workflow-job-structure research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R11/$RUN_ID
git commit -m "feat(research): resolve R11 ci-workflow-job-structure"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 54: R58 logging-pipeline-architecture (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R58/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/58-logging-pipeline-architecture/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/58-logging-pipeline-architecture/prompts/logging-pipeline-architecture.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: logging-pipeline-contract
- Produces: a `resolved` index row for R58, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R58 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R58` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R58 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R58/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R58 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R58 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R58 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R58 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R58 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R58 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R58 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R58 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R58 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R58 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R58 (bundle, owns: logging-pipeline-contract). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R58. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R58. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R58 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/58-logging-pipeline-architecture research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R58/$RUN_ID
git commit -m "feat(research): resolve R58 logging-pipeline-architecture"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 55: R51 container-image (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R51/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/51-container-image/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/51-container-image/prompts/container-image.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R51, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R51 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R51` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R51 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R51/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R51 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R51 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R51 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R51 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R51 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R51 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R51 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R51. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R51. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R51 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/51-container-image research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R51/$RUN_ID
git commit -m "feat(research): resolve R51 container-image"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 56: R70 http-problem-envelope (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R70/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/70-http-problem-envelope/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/70-http-problem-envelope/prompts/http-problem-envelope.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R67, R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R70, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R70 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R70` is listed under `ready` (all of R67, R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R70 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R70/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R70 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R70 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R70 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R70 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R70 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R70 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R70 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R67, research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R70. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R70. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R70 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/70-http-problem-envelope research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R70/$RUN_ID
git commit -m "feat(research): resolve R70 http-problem-envelope"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 57: R72 api-pagination (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R72/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/72-api-pagination/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/72-api-pagination/prompts/api-pagination.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R72, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R72 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R72` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R72 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R72/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R72 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R72 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R72 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R72 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R72 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R72 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R72 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R72 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R72 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R72 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R72 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R72. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R72. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R72 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/72-api-pagination research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R72/$RUN_ID
git commit -m "feat(research): resolve R72 api-pagination"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 58: R73 idempotency-middleware (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R73/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/73-idempotency-middleware/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/73-idempotency-middleware/prompts/idempotency-middleware.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R73, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R73 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R73` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R73 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R73/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R73 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R73 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R73 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R73 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R73 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R73 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R73 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R73 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R73 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R73 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R73 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R73. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R73. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R73 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/73-idempotency-middleware research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R73/$RUN_ID
git commit -m "feat(research): resolve R73 idempotency-middleware"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 59: R74 rate-limiting-middleware (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R74/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/74-rate-limiting-middleware/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/74-rate-limiting-middleware/prompts/rate-limiting-middleware.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R74, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R74 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R74` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R74 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R74/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R74 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R74 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R74 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R74 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R74 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R74 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R74 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R74 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R74 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R74 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R74 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R74. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R74. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R74 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/74-rate-limiting-middleware research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R74/$RUN_ID
git commit -m "feat(research): resolve R74 rate-limiting-middleware"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 60: R76 cors-middleware (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R76/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/76-cors-middleware/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/76-cors-middleware/prompts/cors-middleware.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R76, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R76 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R76` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R76 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R76/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R76 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R76 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R76 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R76 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R76 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R76 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R76 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R76. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R76. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R76 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/76-cors-middleware research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R76/$RUN_ID
git commit -m "feat(research): resolve R76 cors-middleware"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 61: R77 web-env-settings (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R77/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/77-web-env-settings/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/77-web-env-settings/prompts/web-env-settings.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R77, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R77 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R77` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R77 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R77/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R77 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R77 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R77 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R77 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R77 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R77 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R77 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R77. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R77. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R77 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/77-web-env-settings research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R77/$RUN_ID
git commit -m "feat(research): resolve R77 web-env-settings"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 62: R79 prometheus-metrics (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R79/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/79-prometheus-metrics/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/79-prometheus-metrics/prompts/prometheus-metrics.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R79, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R79 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R79` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R79 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R79/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R79 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R79 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R79 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R79 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R79 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R79 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R79 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R79. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R79. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R79 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/79-prometheus-metrics research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R79/$RUN_ID
git commit -m "feat(research): resolve R79 prometheus-metrics"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 63: R80 health-probe-endpoints (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R80/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/80-health-probe-endpoints/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/80-health-probe-endpoints/prompts/health-probe-endpoints.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R80, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R80 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R80` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R80 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R80/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R80 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R80 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R80 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R80 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R80 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R80 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R80 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R80. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R80. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R80 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/80-health-probe-endpoints research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R80/$RUN_ID
git commit -m "feat(research): resolve R80 health-probe-endpoints"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 64: R83 openapi-contract-fuzzing (crate, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R83/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/83-openapi-contract-fuzzing/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/83-openapi-contract-fuzzing/prompts/openapi-contract-fuzzing.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites R71; owned parameters: —
- Produces: a `resolved` index row for R83, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R83 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R83` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R83 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R83/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R83 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R83 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R83 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R83 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R83 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R83 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R83 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R83. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R83. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R83 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/83-openapi-contract-fuzzing research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R83/$RUN_ID
git commit -m "feat(research): resolve R83 openapi-contract-fuzzing"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 65: R84 openapi-typed-client-generation (crate, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R84/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/84-openapi-typed-client-generation/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/84-openapi-typed-client-generation/prompts/openapi-typed-client-generation.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites R71; owned parameters: —
- Produces: a `resolved` index row for R84, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R84 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R84` is listed under `ready` (all of R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R84 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R84/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R84 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R84 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R84 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R84 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R84 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R84 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R84 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R84 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R84 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R84 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R84 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R84. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R84. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R84 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/84-openapi-typed-client-generation research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R84/$RUN_ID
git commit -m "feat(research): resolve R84 openapi-typed-client-generation"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 66: R08 workflow-permission-hardening (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R08/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/08-workflow-permission-hardening/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/08-workflow-permission-hardening/prompts/workflow-permission-hardening.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R08, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R08 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R08` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R08 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R08/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R08 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R08 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R08 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R08 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R08 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R08 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R08 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R08. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R08. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R08 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/08-workflow-permission-hardening research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R08/$RUN_ID
git commit -m "feat(research): resolve R08 workflow-permission-hardening"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 67: R09 self-hosted-runner-indirection (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R09/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/09-self-hosted-runner-indirection/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/09-self-hosted-runner-indirection/prompts/self-hosted-runner-indirection.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R09, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R09 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R09` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R09 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R09/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R09 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R09 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R09 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R09 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R09 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R09 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R09 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R09. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R09. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R09 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/09-self-hosted-runner-indirection research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R09/$RUN_ID
git commit -m "feat(research): resolve R09 self-hosted-runner-indirection"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 68: R12 aggregate-required-status-check (pattern, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R12/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/12-aggregate-required-status-check/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/12-aggregate-required-status-check/prompts/aggregate-required-status-check.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R12, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R12 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R12` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R12 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R12/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R12 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R12 (pattern). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R12 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R12 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R12 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R12 (pattern). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md pattern
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md pattern
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R12 (pattern, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R12. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R12. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R12 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/12-aggregate-required-status-check research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R12/$RUN_ID
git commit -m "feat(research): resolve R12 aggregate-required-status-check"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 69: R13 dependency-vulnerability-scanning (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R13/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/13-dependency-vulnerability-scanning/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/13-dependency-vulnerability-scanning/prompts/dependency-vulnerability-scanning.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R13, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R13 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R13` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R13 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R13/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R13 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R13 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R13 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R13 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R13 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R13 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R13 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R13. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R13. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R13 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/13-dependency-vulnerability-scanning research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R13/$RUN_ID
git commit -m "feat(research): resolve R13 dependency-vulnerability-scanning"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 70: R14 large-file-guard-strategy (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R14/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/14-large-file-guard-strategy/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/14-large-file-guard-strategy/prompts/large-file-guard-strategy.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R14, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R14 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R14` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R14 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R14/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R14 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R14 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R14 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R14 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R14 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R14 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R14 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R14. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R14. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R14 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/14-large-file-guard-strategy research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R14/$RUN_ID
git commit -m "feat(research): resolve R14 large-file-guard-strategy"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 71: R27 formatter-config-surface (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R27/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/27-formatter-config-surface/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/27-formatter-config-surface/prompts/formatter-config-surface.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11, R42 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R27, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R27 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R27` is listed under `ready` (all of R11, R42 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R27 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R27/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R27 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R27 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R27 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R27 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R27 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R27 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R27 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R42. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R27. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R27. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R27 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/27-formatter-config-surface research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R27/$RUN_ID
git commit -m "feat(research): resolve R27 formatter-config-surface"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 72: R28 linter-and-editor-tooling (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R28/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/28-linter-and-editor-tooling/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/28-linter-and-editor-tooling/prompts/linter-and-editor-tooling.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11, R42 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R28, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R28 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R28` is listed under `ready` (all of R11, R42 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R28 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R28/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R28 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R28 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R28 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R28 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R28 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R28 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R28 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R42. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R28. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R28. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R28 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/28-linter-and-editor-tooling research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R28/$RUN_ID
git commit -m "feat(research): resolve R28 linter-and-editor-tooling"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 73: R29 non-code-file-formatting (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R29/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/29-non-code-file-formatting/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/29-non-code-file-formatting/prompts/non-code-file-formatting.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11, R42 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R29, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R29 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R29` is listed under `ready` (all of R11, R42 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R29 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R29/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R29 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R29 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R29 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R29 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R29 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R29 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R29 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R42. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R29. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R29. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R29 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/29-non-code-file-formatting research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R29/$RUN_ID
git commit -m "feat(research): resolve R29 non-code-file-formatting"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 74: R30 type-check-gate (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R30/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/30-type-check-gate/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/30-type-check-gate/prompts/type-check-gate.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R30, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R30 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R30` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R30 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R30/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R30 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R30 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R30 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R30 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R30 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R30 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R30 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R30. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R30. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R30 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/30-type-check-gate research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R30/$RUN_ID
git commit -m "feat(research): resolve R30 type-check-gate"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 75: R31 standalone-security-analyzer (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R31/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/31-standalone-security-analyzer/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/31-standalone-security-analyzer/prompts/standalone-security-analyzer.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R31, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R31 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R31` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R31 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R31/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R31 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R31 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R31 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R31 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R31 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R31 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R31 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R31. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R31. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R31 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/31-standalone-security-analyzer research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R31/$RUN_ID
git commit -m "feat(research): resolve R31 standalone-security-analyzer"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 76: R32 test-harness-and-execution (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R32/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/32-test-harness-and-execution/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/32-test-harness-and-execution/prompts/test-harness-and-execution.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R01, R11, R42, R49, R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R32, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R32 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R32` is listed under `ready` (all of R01, R11, R42, R49, R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R32 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R32/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R32 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R32 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R32 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R32 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R32 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R32 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R32 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R32 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R32 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R32 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R32 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R01, research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R42, research/topics/<nn>-<slug>/DECISION.md of R49, research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R32. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R32. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R32 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/32-test-harness-and-execution research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R32/$RUN_ID
git commit -m "feat(research): resolve R32 test-harness-and-execution"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 77: R35 coverage-tooling (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R35/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/35-coverage-tooling/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/35-coverage-tooling/prompts/coverage-tooling.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R35, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R35 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R35` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R35 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R35/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R35 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R35 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R35 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R35 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R35 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R35 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R35 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R35. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R35. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R35 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/35-coverage-tooling research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R35/$RUN_ID
git commit -m "feat(research): resolve R35 coverage-tooling"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 78: R37 hook-manager-distribution (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R37/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/37-hook-manager-distribution/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/37-hook-manager-distribution/prompts/hook-manager-distribution.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11, R38, R42, R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R37, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R37 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R37` is listed under `ready` (all of R11, R38, R42, R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R37 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R37/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R37 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R37 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R37 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R37 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R37 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R37 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R37 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R38, research/topics/<nn>-<slug>/DECISION.md of R42, research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R37. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R37. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R37 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/37-hook-manager-distribution research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R37/$RUN_ID
git commit -m "feat(research): resolve R37 hook-manager-distribution"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 79: R39 secret-scanning-hooks (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R39/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/39-secret-scanning-hooks/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/39-secret-scanning-hooks/prompts/secret-scanning-hooks.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R39, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R39 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R39` is listed under `ready` (all of R11 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R39 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R39/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R39 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R39 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R39 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R39 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R39 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R39 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R39 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R39. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R39. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R39 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/39-secret-scanning-hooks research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R39/$RUN_ID
git commit -m "feat(research): resolve R39 secret-scanning-hooks"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 80: R40 auxiliary-hygiene-hooks (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R40/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/40-auxiliary-hygiene-hooks/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/40-auxiliary-hygiene-hooks/prompts/auxiliary-hygiene-hooks.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11, R42 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R40, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R40 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R40` is listed under `ready` (all of R11, R42 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R40 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R40/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R40 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R40 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R40 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R40 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R40 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R40 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R40 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R42. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R40. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R40. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R40 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/40-auxiliary-hygiene-hooks research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R40/$RUN_ID
git commit -m "feat(research): resolve R40 auxiliary-hygiene-hooks"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 81: R59 file-log-sink (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R59/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/59-file-log-sink/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/59-file-log-sink/prompts/file-log-sink.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R58 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R59, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R59 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R59` is listed under `ready` (all of R58 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R59 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R59/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R59 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R59 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R59 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R59 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R59 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R59 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R59 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R58. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R59. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R59. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R59 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/59-file-log-sink research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R59/$RUN_ID
git commit -m "feat(research): resolve R59 file-log-sink"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 82: R71 openapi-generation-pipeline (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R71/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/71-openapi-generation-pipeline/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/71-openapi-generation-pipeline/prompts/openapi-generation-pipeline.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11, R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R71, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R71 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R71` is listed under `ready` (all of R11, R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R71 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R71/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R71 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R71 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R71 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R71 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R71 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R71 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R71 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R71 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R71 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R71 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R71 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R71. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R71. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R71 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/71-openapi-generation-pipeline research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R71/$RUN_ID
git commit -m "feat(research): resolve R71 openapi-generation-pipeline"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 83: R75 http-middleware-stack (bundle, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R75/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/75-http-middleware-stack/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/75-http-middleware-stack/prompts/http-middleware-stack.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R58, R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R75, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R75 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R75` is listed under `ready` (all of R58, R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R75 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R75/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R75 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R75 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R75 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R75 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R75 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R75 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R75 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R75 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R75 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R75 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R75 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R58, research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R75. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R75. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R75 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/75-http-middleware-stack research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R75/$RUN_ID
git commit -m "feat(research): resolve R75 http-middleware-stack"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 84: R78 opentelemetry-integration (crate, deep; engines codex, opus, doxa)

**Files:**
- Run directory (create via the runner): `research/runs/R78/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/78-opentelemetry-integration/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/78-opentelemetry-integration/prompts/opentelemetry-integration.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R58, R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R78, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R78 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R78` is listed under `ready` (all of R58, R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R78 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R78/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R78 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R78 (crate). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R78 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R78 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R78 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R78 (crate). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

Doxa (paid; single attempt per provider):

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R78 --run-id $RUN_ID --provider doxa --actor research-doxa-$RUN_ID --model all_deep_research
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml ask --mode all_deep_research --prompt-file $RUN_DIR/inputs/prompt.md --output-dir $RUN_DIR/doxa --combined --async --json > $RUN_DIR/operations/doxa-submit.json 2> $RUN_DIR/operations/doxa-submit.stderr; echo exit=$?
# operation_id from doxa-submit.json; if absent: uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run unknown R78 --run-id $RUN_ID --provider doxa --reason "<what was observed>" and reconcile with doxa list --all --json against docs/planning/p02/probes/doxa-inventory-baseline-summary.json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R78 --run-id $RUN_ID --provider doxa --operation-id <operation_id> --actual-provider openai+perplexity+gemini --actual-model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
# later, poll no more than every 5 minutes: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml status <operation_id> --json ; when complete, resume/collect: /Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py --config docs/planning/p02/doxa-pilot.config.toml resume <operation_id> (writes the provider files and the combined file under $RUN_DIR/doxa)
cp $RUN_DIR/doxa/<combined file>.md $RUN_DIR/raw/doxa.md
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R78 --run-id $RUN_ID --provider doxa --state succeeded --raw-file raw/doxa.md --actor research-doxa-$RUN_ID --model "gpt-5.6-sol; sonar-deep-research; deep-research-preview-04-2026"
```

A partial result (some providers failed) is collected with `--state failed --reason <provider outcomes>` after preserving every provider file; no resubmission without a new recorded approval. Record measured usage from the Doxa metadata in the ledger.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md crate
scripts/check-answer-shape.sh $RUN_DIR/raw/doxa.md crate
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R78 (crate, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md, $RUN_DIR/raw/doxa.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R58, research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R78. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R78. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R78 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/78-opentelemetry-integration research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R78/$RUN_ID
git commit -m "feat(research): resolve R78 opentelemetry-integration"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 85: R82 docs-correctness-gate (bundle, focused; engines codex, opus)

**Files:**
- Run directory (create via the runner): `research/runs/R82/<RUN_ID>/` with `raw/`, `review/`, `operations/`
- Published by the runner only: `research/topics/82-docs-correctness-gate/DECISION.md`, `acceptance.json`, `audit-codex.md`, `audit-fable.md`, `raw/<engine>-<RUN_ID>.md`, `evidence/*.log`, `research/CLAUDE.md`, `docs/port/PARAMETERS.md`
- Prompt (read-only): `research/topics/82-docs-correctness-gate/prompts/docs-correctness-gate.prompt.md`

**Interfaces:**
- Consumes: research prerequisites R11, R69 (each must be `resolved` with a current `DECISION.md`; consumed parameter values come from those decisions); acceptance prerequisites none; owned parameters: —
- Produces: a `resolved` index row for R82, its `DECISION.md` and acceptance bundle, and the owned parameter value(s) in `docs/port/PARAMETERS.md`, consumed by the items that list R82 on their `- consumes:` line

- [ ] **Step 1: Admit the item and prepare the run (controller)**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json queue list` and confirm `R82` is listed under `ready` (all of R11, R69 resolved). Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run prepare R82 --actor controller-fable-5-1 --model claude-fable-5-1 --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining of the USD 300 bulk ceiling, or 'no paid engine' for Light/Focused>"
```

Record `RUN_ID` and `RUN_DIR=research/runs/R82/$RUN_ID` from the result.

- [ ] **Step 2: Produce the raw reports in parallel (one fresh actor per engine)**

For each engine, first record intent, then run the engine, then collect:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R82 --run-id $RUN_ID --provider codex --actor research-codex-$RUN_ID --model gpt-5.6-terra
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o raw/codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/research-worker.md, then inputs/prompt.md in this directory. Item R82 (bundle). Actor id research-codex-$RUN_ID. Write your report to raw/codex.md in this directory and nothing else." > raw/codex-transcript.txt 2>&1 < /dev/null
grep -m1 '^model:' $RUN_DIR/raw/codex-transcript.txt   # identity for identities.json
# operation id = the Codex rollout thread id (~/.codex/sessions/<date>/rollout-<time>-<thread>.jsonl whose cwd is $RUN_DIR)
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run submitted R82 --run-id $RUN_ID --provider codex --operation-id <thread id> --actual-provider codex-cli-0.153.2 --actual-model <header model>
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run collect R82 --run-id $RUN_ID --provider codex --state succeeded --raw-file raw/codex.md --actor research-codex-$RUN_ID --model gpt-5.6-terra
```

Opus: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json run intent R82 --run-id $RUN_ID --provider opus --actor research-opus-$RUN_ID --model claude-opus-5`; dispatch an Agent-tool subagent with `model: opus`, prompt: "Read docs/superpowers/plans/p02-roles/research-worker.md, then $RUN_DIR/inputs/prompt.md. Item R82 (bundle). Actor id research-opus-$RUN_ID. Write your report to $RUN_DIR/raw/opus.md and nothing else. Quote the exact model ID from your system prompt in your reply."; then `run submitted ... --provider opus --operation-id agent:research-opus-$RUN_ID:<first 16 hex of the report's sha256> --actual-provider claude-agent-tool --actual-model <reported id>` and `run collect ... --provider opus --state succeeded --raw-file raw/opus.md --actor research-opus-$RUN_ID --model <reported id>`.

- [ ] **Step 3: Shape-check every raw report**

```bash
scripts/check-answer-shape.sh $RUN_DIR/raw/codex.md bundle
scripts/check-answer-shape.sh $RUN_DIR/raw/opus.md bundle
```

Expected: `OK` for each. A cosmetic defect (heading spelling, fence boundary) is fixed in a lossless copy `raw/<engine>.normalized.md` whose first line reads `<!-- normalized from raw/<engine>.md sha256 <hash> -->`; re-check the copy. A substantive gap (missing field body, missing figures) is a bounded supplementary request to the same engine with the reason recorded in the ledger; never fill it in yourself.

- [ ] **Step 4: Synthesize the decision (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable`, prompt: "Read docs/superpowers/plans/p02-roles/synthesizer.md. Run directory $RUN_DIR. Item R82 (bundle, owns: —). Raw reports: $RUN_DIR/raw/codex.md, $RUN_DIR/raw/opus.md (use the .normalized.md copy where one exists). Prerequisite decisions: research/topics/<nn>-<slug>/DECISION.md of R11, research/topics/<nn>-<slug>/DECISION.md of R69. Actor id synth-fable-$RUN_ID. Write $RUN_DIR/review/DECISION.md and the evidence log; quote your exact model ID in the reply." Confirm the reply names the empirical command, its exit status and the log path.

- [ ] **Step 5: Empirical audit (fresh Codex Terra)**

```bash
/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex exec --skip-git-repo-check --color never -m gpt-5.6-terra -c 'model_reasoning_effort="high"' -c 'approval_policy="never"' --sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -C $RUN_DIR -o review/audit-codex-receipt.txt "Read /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/superpowers/plans/p02-roles/empirical-auditor.md. Item R82. Actor id audit-codex-$RUN_ID; model id gpt-5.6-terra. Write review/audit-codex.md and review/evidence/audit-<short-name>.log in this directory and nothing else." > review/audit-codex-transcript.txt 2>&1 < /dev/null
```

- [ ] **Step 6: Judgment audit (fresh Fable)**

Dispatch an Agent-tool subagent with `model: fable` (a different subagent from the synthesizer), prompt: "Read docs/superpowers/plans/p02-roles/judgment-auditor.md. Run directory $RUN_DIR. Item R82. Actor id audit-fable-$RUN_ID; model id from your system prompt. Write $RUN_DIR/review/audit-fable.md and nothing else."

- [ ] **Step 7: Resolve findings (fix loop, at most five rounds)**

If either verdict is `reject`, resume the synthesizer subagent with both audits' findings verbatim (rounds 1–3; a fresh `fable` synthesizer with the report and findings for rounds 4–5). The revised `review/DECISION.md` is audited again by NEW fresh auditors (new actor ids `audit-codex-$RUN_ID-r<N>` and `audit-fable-$RUN_ID-r<N>`), never by the previous ones. Any `CONFLICT:` line stops this task: record `Task <N>: blocked — CONFLICT ...` in the ledger and follow runbook §4 before resuming.

- [ ] **Step 8: Package and publish (controller)**

Write `$RUN_DIR/review/identities.json` (schema in Task 1) from the recorded actors, header model lines and reported model IDs, and the empirical rerun's argv, cwd, toolchain, log and exit code from `review/audit-codex.md`. Then:

```bash
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_package.py build --root . --item R82 --run-id $RUN_ID --staged-dir $RUN_DIR/staged --json
uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_runner.py --json publication apply --file $RUN_DIR/staged/manifest.json --staged-dir $RUN_DIR/staged
scripts/check-research-tree.sh --require-owner-review
git add research/topics/82-docs-correctness-gate research/CLAUDE.md docs/port/PARAMETERS.md docs/port/COMMONALITY.md research/runs/R82/$RUN_ID
git commit -m "feat(research): resolve R82 docs-correctness-gate"
```

Expected: the publication result is `ok`, the run state becomes `published`, the checker prints `OK: research tree structure valid`, and `git log -1` shows the new commit. Do not stage `research/runs/.locks/` or any `target/` directory.

### Task 86: Close P02

**Files:**
- Modify: `PROJECTS.md` (P02 task rows T01–T06, TS01, TS02), `docs/planning/p02/README.md`
- Read-only: `research/CLAUDE.md`, `docs/port/PARAMETERS.md`

**Interfaces:**
- Consumes: every index row `resolved`; every registry `researched` row valued.
- Produces: the branch ready for the whole-branch review and the owner's PR, merge and `v0.2.0` decisions (P02-T07 is the owner's).

- [ ] **Step 1: Verify the deliverable**

```bash
grep -c '| resolved |' research/CLAUDE.md      # must print 84
grep -c '| researched | R[0-9][0-9] | — |' docs/port/PARAMETERS.md   # must print 0
scripts/check-research-tree.sh --require-owner-review
for t in scripts/test-check-research-tree.sh; do $t | tail -1; done
for t in scripts/test-research-validation.py scripts/test-research-runner.py scripts/test-research-answer-parser.py scripts/test-research-reader-lock.py scripts/test-derive-port-docs.py scripts/test-doxa-no-retry.py scripts/test-research-package.py; do uv run --offline --no-project --no-python-downloads --no-cache python3 $t 2>&1 | tail -1; done
```

- [ ] **Step 2: P02-TS01 and P02-TS02 reviews**

Dispatch one `fable` reviewer with the ledger's deferred and parked lines and this brief: for every `DECISION.md`, confirm the `## Empirical check` command was executed and its output pasted (P02-TS01); verify the principle-to-design mapping and agreement level in every decision, then re-read every OVERRIDE item's "Override justified" field; any `no` flips the ledger row back to the inherited verdict and records the reversal under `### OV-nn` (P02-TS02). Findings go through one fix dispatch and one scoped re-review.

- [ ] **Step 3: Update tracking and commit**

Mark P02-T01 through P02-T06, TS01 and TS02 `[x]` in `PROJECTS.md` with dates; leave P02-T07 open for the owner. Update `docs/planning/p02/README.md`'s status line. Commit with `docs(p02): close research execution`. Then use superpowers:finishing-a-development-branch and stop: pushing, the PR, the merge and the `v0.2.0` tag are the owner's decisions.

### Task 87: Doxa replacement-model shim for the shut-down OpenAI deep-research models

**Files:**
- Modify: `scripts/doxa_no_retry.py`
- Modify: `scripts/test-doxa-no-retry.py`
- Modify: `docs/planning/p02/doxa-pilot.config.toml`
- Modify: `docs/planning/p02/paid-envelope.md` (price table), `docs/planning/p02/tool-readiness.md` (re-inspection section)
- Reference (read only): `/Users/stevemorin/c/doxa-research/src/doxa_research/config.py` (`is_background_model`, line 361), `/Users/stevemorin/c/doxa-research/src/doxa_research/providers/openai.py` (`_submit_with_retry`, lines 321–390: tools, background, temperature, `max_tool_calls`), `/Users/stevemorin/c/doxa-research/src/doxa_research/progress.py`

**Interfaces:**
- Consumes: the existing launcher (`apply_patches`, `effective_settings`, `PATCH_TARGETS`) and its test harness (`_verify`, `DOXA_PYTHON`).
- Produces: `DEEP_RESEARCH_REPLACEMENTS = {"gpt-5.6-sol"}` in `scripts/doxa_no_retry.py`; after `apply_patches()`, `is_background_model("gpt-5.6-sol")` is `True` in `doxa_research.config`, in `doxa_research.providers.openai` and in `doxa_research.progress` (patch every module that bound the name); every call to `openai.resources.responses.AsyncResponses.create` whose `model` starts with `gpt-5` has the `temperature` keyword removed and every tool `{"type": "web_search_preview"}` rewritten to `{"type": "web_search"}` (other kwargs unchanged, other models untouched); `--verify` JSON gains `"deep_research_replacements": ["gpt-5.6-sol"]`, `"responses_create_shim": true|false` and `"background_model_gpt_5_6_sol": true|false`.

Facts the implementer needs: OpenAI shut down `o3-deep-research` and `o4-mini-deep-research` on 2026-07-23 (announced 2026-04-22) and names `gpt-5.6-sol` as the replacement (https://developers.openai.com/api/docs/deprecations, retrieved 2026-09-05). `gpt-5.6-sol` supports the Responses endpoint and the `web_search`, `code_interpreter`, `file_search` and `mcp` tools, not `web_search_preview`; price USD 4 per 1M input tokens, USD 0.40 cached input, USD 20 output; 1,050,000 context, 128,000 max output (https://developers.openai.com/api/docs/models/gpt-5.6-sol, retrieved 2026-09-05). A job-free validation probe (`POST /v1/responses` with `"input": []`) returned `missing_required_parameter` for `gpt-5.6-sol` and `model_not_found` for `o3-deep-research`. Doxa's OpenAI provider adds `temperature` for any model not starting with `o`, adds tools only when `is_background_model(model)` is true, and forces `background=True` for such models or when the mode config sets `background`.

- [ ] **Step 1: Write the failing tests**

Add to `scripts/test-doxa-no-retry.py` (same skip rule as the existing tests):

```python
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
    result = subprocess.run([str(DOXA_PYTHON), "-c", code], capture_output=True, text=True, timeout=120, check=True, cwd=ROOT)
    first, second = json.loads(result.stdout)
    self.assertNotIn("temperature", first)
    self.assertEqual(first["tools"], [{"type": "web_search"}, {"type": "code_interpreter"}])
    self.assertTrue(first["background"])
    self.assertEqual(second["temperature"], 0.7)
    self.assertEqual(second["tools"], [{"type": "web_search_preview"}])
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/test-doxa-no-retry.py`
Expected: the two new tests FAIL (`KeyError: 'background_model_gpt_5_6_sol'` and `AttributeError: ... has no attribute 'shim_responses_create'`); the four existing tests still pass.

- [ ] **Step 3: Implement the shim**

In `scripts/doxa_no_retry.py`: add `DEEP_RESEARCH_REPLACEMENTS = {"gpt-5.6-sol"}`; add `shim_responses_create(original)` returning an `async def create(self, **kwargs)` that applies the two rewrites when `str(kwargs.get("model", "")).startswith("gpt-5")` and then awaits `original(self, **kwargs)`; in `apply_patches()` (a) wrap `is_background_model` so it returns `True` for the replacements and otherwise defers to the original, rebinding the name in `doxa_research.config`, `doxa_research.providers.openai` and `doxa_research.progress` (import each; skip a module that does not bind the name), (b) replace `openai.resources.responses.AsyncResponses.create` with `shim_responses_create(original)` and mark it with `__doxa_shim__ = True`; in `effective_settings()` add the three report keys (`responses_create_shim` = whether the marker is present; `background_model_gpt_5_6_sol` = `doxa_research.providers.openai.is_background_model("gpt-5.6-sol")`). Update the module docstring to name the shim and the shutdown date.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/test-doxa-no-retry.py`
Expected: `OK` with 6 tests.

- [ ] **Step 5: Update the pilot config and records**

In `docs/planning/p02/doxa-pilot.config.toml`, under `[modes.all_deep_research.openai]` add `model = "gpt-5.6-sol"` and `background = true` (keep `max_tool_calls = 80` and `code_interpreter = false`) with a comment naming the 2026-07-23 shutdown and the vendor replacement; verify with `/Users/stevemorin/c/doxa-research/.venv/bin/doxa -c docs/planning/p02/doxa-pilot.config.toml modes list --name all_deep_research --json` that `raw.openai.model` is `gpt-5.6-sol`. In `docs/planning/p02/paid-envelope.md` replace the OpenAI row of the price table and the operation table's model with `gpt-5.6-sol` and its prices (source URL and 2026-09-05), and recompute the OpenAI estimate line with the new prices under the same token assumptions. In `docs/planning/p02/tool-readiness.md` append to the re-inspection table a row `Deep-research model availability` recording that the list endpoint still returns the shut-down models, that the job-free Responses validation probe is the correct access check, and that the pilot uses `gpt-5.6-sol` through the launcher's shim.

- [ ] **Step 6: Commit**

```bash
git add scripts/doxa_no_retry.py scripts/test-doxa-no-retry.py docs/planning/p02/doxa-pilot.config.toml docs/planning/p02/paid-envelope.md docs/planning/p02/tool-readiness.md
git commit -m "fix(research): drive the replacement OpenAI deep-research model through the Doxa launcher"
```
