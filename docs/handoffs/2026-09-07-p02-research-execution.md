# Session handoff — P02 research execution — 2026-09-07

## 🎯 Outcome

**Goal:** resolve all 84 research items in `research/CLAUDE.md`, each with an
audited `DECISION.md` published through the durable runner, until
`docs/port/PARAMETERS.md` is fully valued and
`scripts/check-research-tree.sh --require-owner-review` passes with every index
row `resolved`. Three are done; 81 remain.

**Out of scope:** writing the Rust template itself (that is P03), the pull
request, the merge, and the `v0.2.0` tag. Those stay with the owner.

**Self-contained:** ✓ stands alone. Everything load-bearing is committed on this
branch; the sections below inline the rulings and the per-item state rather than
pointing at them.

## ⚠ Portability preflight — read first

| Concern | Status |
|---|---|
| Uncommitted work | none once the commit carrying this file lands |
| Unpushed commits | pushed to `origin/research/p02-execution` |
| Execution ledger | was git-ignored; copied to `docs/planning/p02/execution-ledger.md` so it travels |
| Codex rollout files | `~/.codex/sessions` is machine-local and does **not** travel; the operation ids it proves are already recorded in each run's `manifest.json`, which does |
| Lima virtual machine | machine-local; recreate it for Linux acceptance legs (recipe below) |
| Doxa virtual environment | machine-local at `/Users/stevemorin/c/doxa-research/.venv`; two files hardcode that path and must be repointed |
| Worker fixture trees | git-ignored on purpose (`tools/`, `target/`, `node_modules/`, `vendor/`, `raw/fixture-*`); a rerun reinstalls them from the recorded pins |

## 🧭 Where you are

- **Repo:** `rs-launch-blueprint` · origin `https://github.com/smorinlabs/rs-launch-blueprint.git` · default branch `main`
- **Branch:** `research/p02-execution` (renamed 2026-09-07 from `docs/p02-execution-plan-review`)
- **Base:** `origin/main` = `2f3569051af2c2089f60f6cad129bc6e55482c30`, which is also where the `v0.1.0` tag points
- **Repo root on the machine that wrote this:** `/Users/stevemorin/c/rs-launch-blueprint-p02-plan` (a worktree of `/Users/stevemorin/c/rs-launch-blueprint`) — yours will differ
- **Verify the tree:**

```bash
scripts/check-research-tree.sh --require-owner-review     # expect: OK: research tree structure valid
scripts/test-check-research-tree.sh | tail -1             # expect: 53 passed, 0 failed
for t in test-research-validation test-research-runner test-research-answer-parser \
         test-research-reader-lock test-derive-port-docs test-doxa-no-retry test-research-package; do
  uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/$t.py 2>&1 | tail -1
done                                                      # expect: OK from each
```

## 🛑 Three blockers — all cleared 2026-09-08

All three stopped work on 2026-09-05 and have since been verified working; the
original symptoms are kept below so the record reads honestly. Evidence:
`docs/planning/p02/probes/provider-verification-2026-09-08.txt` and the dated
section at the end of `docs/planning/p02/tool-readiness.md`.

1. **Claude usage credits exhausted.** Terminated three subagents mid-task (HTTP 429, "You're out of usage credits"). This gates every synthesis and judgment audit.
2. **OpenAI credits exhausted.** The R38 pilot's OpenAI job was created and failed immediately with `credit_balance_exhausted`; zero tokens were billed. Job id `resp_004c14d621f391d2006a9c3ad2f14887d0b228550d2c17554f`.
3. **Perplexity quota exhausted.** `GET https://api.perplexity.ai/async/chat/completions` returns HTTP 401 `insufficient_quota`.

**Cleared 2026-09-08.** One trivial paid call per provider through
`scripts/doxa_no_retry.py` returned real content: OpenAI `4`, Perplexity `4`
with sources, Gemini `4`. `doxa providers check` reports `complete: true`.
Claude credits are evidenced by this session running, though subagent dispatch
has not been separately retested since the outage.

The deep-research models were then exercised with a trivial question.
`gpt-5.6-sol` answered in 17 seconds for about USD 0.03, with the API
confirming the launcher shim set `background: true` and `tools: ['web_search']`.
`sonar-deep-research` answered in 61 seconds for a self-reported USD 0.329,
settling the one model whose access had never been proven.

Gemini deep research was blocked by a stale SDK, **fixed and merged on
2026-09-08**: doxa-research PR #146 raised the floor to `google-genai>=2.0.0`
(lock 2.22.0), and the local environment was reinstalled from merged main. A
full run then returned a 59 KB report with 41 sources in 6m42s. **All three
deep-research engines are now proven working**, so the R38 pilot's fan-out is
unblocked. `o3-deep-research` still returns `model_not_found`, so the shim
remains required regardless.

Approved ceilings are unchanged: USD 40 for pilot batch `B0-R38`, USD 300 total
for the remaining Deep operations, authorization reference
`OWNER-2026-09-05-P02-EXEC`.

## 📎 Artifacts and sources of truth

| What | Path (repo-relative) | Status |
|---|---|---|
| Execution contract | `research/RUNBOOK.md` | ✓ committed, authoritative |
| Machine-readable policy | `research/EXECUTION.json` | ✓ tiers, engines, acceptance prerequisites for all 84 |
| Item index | `research/CLAUDE.md` | ✓ status per item; the publication target |
| Acceptance schema | `docs/planning/p02/acceptance-schema.md` | ✓ what `acceptance.json` must contain |
| Task plan, 87 tasks | `docs/superpowers/plans/2026-09-05-p02-research-execution.md` | ✓ one task per item plus tooling |
| Role prompts | `docs/superpowers/plans/p02-roles/*.md` | ✓ research worker, evidence checker, synthesizer, both auditors |
| Execution ledger | `docs/planning/p02/execution-ledger.md` | ✓ every ruling, identity and verdict so far |
| Dependency graph | `docs/planning/p02/item-graph.json` | ✓ tier, engines and prerequisites per item |
| Paid envelope | `docs/planning/p02/paid-envelope.md` | ✓ prices, caps, exact Doxa invocation |
| Approvals | `docs/planning/p02/APPROVAL.md` | ✓ commit direction, spend ceilings, model substitution |
| Baseline review | `docs/port/BASELINE-REVIEW.md` | ✓ all 97 REUSE/ADOPT rows adjudicated; 9 open owner questions |

## 📋 The per-item loop, inlined

Every item runs the same eight steps. The controller does only admission,
runner commands, packaging and commits; each research and review role is a
**separate fresh subagent**, because the runbook requires actor independence.

1. **Admit and prepare.** `run prepare <ITEM> --actor controller --model <m> --authorization-ref OWNER-2026-09-05-P02-EXEC --budget "<remaining>"`, after confirming the item appears under `queue list`.
2. **Research, one fresh actor per engine.** For each: `run intent` → run the engine → `run submitted --operation-id <id>` → `run collect --state succeeded --raw-file raw/<engine>.md`. Codex ids come from `scripts/codex-thread-for.sh`; Agent-tool ids use `agent:<actor>:<report sha256 prefix>`.
3. **Shape-check every raw.** `scripts/check-answer-shape.sh <file> <crate|pattern|bundle>`. A cosmetic defect is normalized into a `*.normalized.md` copy; a substantive gap is a bounded supplementary request to the same engine.
4. **Synthesize.** A fresh Fable subagent writes `review/DECISION.md` and **actually executes** the empirical check, saving output under `review/evidence/`.
5. **Empirical audit.** A fresh Codex Terra subagent reruns the check from a clean fixture and writes `review/audit-codex.md`.
6. **Judgment audit.** A fresh Fable subagent writes `review/audit-fable.md`.
7. **Fix loop.** If either verdict is `reject`, archive both audits as `audit-*.rN.md`, resume the synthesizer with the findings verbatim, then dispatch a **new** auditor pair. Five rounds maximum, then adjudicate.
8. **Package and publish.** Write `review/identities.json`, then `research_package.py build`, then `research_runner.py publication apply`, then the checker, then commit.

**Capacity:** at most three Claude subagents at once (the controller is the
fourth Claude call); Codex and Doxa run out of process and do not count.

**Waves:** 32 items have no prerequisites (Wave 0, all listed below), then 19,
13 and 20 unlock as their owners publish. R69, R11 and R58 gate most of the rest.

## 🔧 State to resume

Three items are published: **R23** lockfile version sync, **R47** contributors
recipe mode, **R04** public API surface enforcement. Every Wave 0 item has its
Codex report collected. The table gives the exact next action per run.

| Item | T | Index | Run id | Reports in | Decision | Prior audits | Next action |
|---|---|---|---|---|---|---|---|
| R01 | D | open | `2026-09-05T155123Z-52a17c034dad` | codex,opus | - | 0 | research: doxa |
| R04 | F | resolved | `2026-09-05T162359Z-3c50443de1e8` | codex,opus | 0d4f2e60e994 | 0 | done |
| R06 | F | open | `2026-09-05T162400Z-31f07a2b91b6` | codex,opus | - | 0 | synthesize |
| R07 | F | open | `2026-09-05T162400Z-58ba22bff8ca` | codex | - | 0 | research: opus |
| R15 | F | open | `2026-09-05T163018Z-6cb436162ac7` | codex | - | 0 | research: opus |
| R16 | F | open | `2026-09-05T163018Z-61c8f49b581d` | codex | - | 0 | research: opus |
| R17 | F | open | `2026-09-05T163018Z-d7ade3a111f8` | codex | - | 0 | research: opus |
| R18 | D | open | `2026-09-06T043454Z-6f31d86e5b7d` | codex | - | 0 | research: doxa+opus |
| R19 | F | open | `2026-09-06T043454Z-33c81db94a3b` | codex | - | 0 | research: opus |
| R20 | F | open | `2026-09-05T163615Z-417f07db9a2c` | codex | - | 0 | research: opus |
| R21 | F | open | `2026-09-05T163616Z-1ab131aed82d` | codex | - | 0 | research: opus |
| R23 | L | resolved | `2026-09-05T160304Z-11020e4e7e38` | codex | ea269dd6ac33 | 0 | done |
| R25 | D | open | `2026-09-05T164357Z-eec460755121` | codex | - | 0 | research: doxa+opus |
| R26 | F | open | `2026-09-05T164358Z-bb73f46c3910` | codex | - | 0 | research: opus |
| R33 | F | open | `2026-09-05T164358Z-eae89906c763` | codex | - | 0 | research: opus |
| R34 | F | open | `2026-09-05T165440Z-d2e35904dc88` | codex | - | 0 | research: opus |
| R38 | F | open | `2026-09-05T151356Z-c46d732f98ed` | codex,opus | 2fc432d4384b | 3 | package + publish |
| R41 | L | open | `2026-09-05T160304Z-1e904d50d29e` | codex | bcbae3f7ded0 | 2 | fresh audit pair (revision 2) |
| R42 | D | open | `2026-09-05T155503Z-4141a35b69e0` | codex,opus | - | 0 | research: doxa |
| R43 | F | open | `2026-09-05T165440Z-3a8ca31664c3` | codex | - | 0 | research: opus |
| R45 | F | open | `2026-09-05T165440Z-58f1cbb2e6c5` | codex | - | 0 | research: opus |
| R46 | L | open | `2026-09-05T160304Z-5cba7fe96ae4` | codex | 1876815914f3 | 2 | fresh audit pair (revision 2) |
| R47 | L | resolved | `2026-09-05T160304Z-99a3dd6456c0` | codex | 20693ce171bc | 0 | done |
| R49 | D | open | `2026-09-05T155504Z-2107cffb3ecf` | codex | - | 0 | research: doxa+opus |
| R60 | D | open | `2026-09-05T183002Z-09f93cfc507c` | codex | - | 0 | research: doxa+opus |
| R63 | F | open | `2026-09-05T183003Z-44e034fc1d72` | codex | - | 0 | research: opus |
| R64 | F | open | `2026-09-05T183457Z-3c53ded23d05` | codex | - | 0 | research: opus |
| R65 | F | open | `2026-09-05T183457Z-cc32974b5d89` | codex | - | 0 | research: opus |
| R66 | D | open | `2026-09-05T183458Z-9ff7d91f9b8f` | codex | - | 0 | research: doxa+opus |
| R67 | D | open | `2026-09-05T155124Z-2271e140a7ef` | codex,opus | - | 0 | research: doxa |
| R81 | F | open | `2026-09-05T183003Z-c02279aa76ae` | codex | - | 0 | research: opus |
| R85 | F | open | `2026-09-06T043455Z-beb2d764c756` | codex | - | 0 | research: opus |

**Corrections to the table's mechanical guesses:**

- **R38** shows "package + publish" because both audits approve revision 3. It is
  in fact **blocked**: `research/EXECUTION.json` requires three engines for the
  pilot and the Doxa report does not exist. When Doxa lands, write revision 4
  incorporating it, dispatch a fresh audit pair, then publish. The auditors also
  left three text fixes for that revision: save the isolated-cache `audit-deps`
  diagnostic as its own evidence log, correct the "missing `committed.toml` is not
  a silent pass" claim to "the config is load-bearing", and change "billing
  blocked" to "billing and auth".
- **R41** and **R46** each have a finished revision 2 answering a rejection, with
  the first-round audits archived as `audit-*.r1.md`. Both need a **fresh audit
  pair** next, not a revision.
- **R06** is the only item ready to synthesize immediately.

## 🧠 Context that will not survive a fresh window

### The 16 rulings made on the owner's behalf

Full text with costs is in `docs/planning/p02/execution-ledger.md`; these are the
operative summaries.

1. **Item research may run before the packaging tool exists**; only publication waits for it.
2. **Only `publication apply` writes the shared files** (index, registry, ledger); its writer lock serializes them.
3. **The runbook's actor independence beats the plan skill's one-implementer rule.** Each role is its own fresh subagent; the two runbook audits serve as the task review.
4. **Items run in parallel** across disjoint run directories; only the R38 pilot ran alone.
5. **Run directories are committed** as durable evidence; locks and build outputs are ignored.
6. **Agent-tool identity** is the model id the subagent quotes from its own system prompt, cross-referenced with the CLI probes in `docs/planning/p02/probes/`.
7. **Doxa usage is recorded in the ledger** after each collection; stop paid work at the ceiling.
8. **The OpenAI deep-research model is `gpt-5.6-sol`.** `o3-deep-research` was shut down 2026-07-23; the vendor names the replacement, and `scripts/doxa_no_retry.py` shims it in.
9. **The shim work ran concurrently with the packaging tool** (disjoint files).
10. **Operation ids for out-of-band engines**: Codex uses its rollout thread id; Agent-tool runs use `agent:<actor>:<sha prefix>`.
11. **Unpaid keystone research started before the pilot published**, since the report recipe was already proven.
12. **R38 proceeded through synthesis and both audits as an unpublished draft** while Doxa was blocked.
13. **Light items may publish ahead of the pilot** (they use no paid engine).
14. **A `defective` evidence check goes back to the same Codex session** via `codex exec resume`, then a fresh evidence check follows.
15. **Linux acceptance legs run in a local Lima Ubuntu virtual machine** (aarch64), recording that GitHub's runners are x86_64. CI in P03 is the final arbiter.
16. **Fixture scripts are committed, tool installs are not.** Reruns reinstall from the recorded pins.

### Gotchas that cost real time

- **`codex exec` hangs forever on an open standard input.** Always redirect: `< /dev/null`. Two probes hung 11 and 2.5 minutes before this was found.
- **`codex exec resume` takes different flags** than `codex exec`: it rejects `--color` and `--sandbox`. Use `-c sandbox_mode="workspace-write"` and `-c sandbox_workspace_write.network_access=true`. **Pass `-m` explicitly**, or the resume silently uses the config default (`gpt-6-astra`), which changes the recorded engine identity. This happened to R41 revision 2 and R46 revision 2, and both manifests carry a correction event.
- **Resolve Codex thread ids by working directory, never by grepping rollout bodies.** A text match once gave R47 the thread belonging to R46. `scripts/codex-thread-for.sh` does it correctly.
- **Never let a subagent list another item's run directory.** Two agents stalled for 600 seconds enumerating a fixture tree with 22,000 files.
- **The documented deliverable check is off by one.** `grep -c '| resolved |' research/CLAUDE.md` also matches the legend on line 3. Use `grep -cE '^\| R[0-9]+ \|.*\| resolved \|$'`, which reports 3 today and must reach 84.
- **Doxa's mode config deep-merges.** Omitting `model` from `[modes.all_deep_research.openai]` silently falls back to the shut-down `o3-deep-research` rather than clearing it.
- **Doxa rejects `background` as a mode-level provider key** (`Unsupported provider parameter`); the shim forces background mode through `is_background_model` instead.

### Approaches already rejected, do not redo

- **Launching several Codex workers from one shell loop with space-separated fields.** Word splitting silently ran nothing and produced no error until the run directories were checked.
- **`git add -A` across run directories.** It staged 22,991 files from a vendored fixture containing embedded git repositories. The current `.gitignore` prevents it.
- **Doxa's own retry behaviour.** Left alone it stacks three tenacity attempts on two SDK retries with no idempotency key on OpenAI or Gemini. Every paid call must go through `scripts/doxa_no_retry.py`, which reduces each provider to a single create attempt.

### Nine open owner questions

`docs/port/BASELINE-REVIEW.md` ends with nine questions carrying options and a
recommendation each. None blocks the pipeline. Two gate second-wave keystones:
whether R67 owns the backtrace capture rule (question 9) and how the MSRV floor
crosses the operating-system matrix (question 4, R11).

## 🧰 New machine prerequisites

Install these before dispatching any worker. Every one is machine-local and none
travels with the repository.

| Need | Version used here | Why it matters |
|---|---|---|
| `rustup` with stable and the floor toolchain | rustc 1.98.0 stable, plus 1.96.0 | Empirical checks run on both; the floor is `stable minus 2 minors` under the fixed MSRV policy |
| Node with the Codex CLI | Node 26.5.0, `codex-cli 0.153.2` | Every research report and empirical audit runs through `codex exec`; must be logged in (`codex login status`) |
| Claude Code | 2.1.261 | Synthesis and judgment audits; must be logged in and have usage credits |
| `uv` | any recent | Every Python tool runs as `uv run --offline --no-project --no-python-downloads --no-cache python3 <script>` |
| `just`, `git`, `jq`, `curl` | just 1.57.0, git 2.50.1 | Fixtures and evidence gathering |
| Lima | 2.2.0 | Linux acceptance legs |

**Doxa.** Clone `smorinlabs/doxa-research` at commit
`ba423be7e96461962ae0fde21373e5e10aeecae2` and build a virtual environment for
it (Python 3.11, `openai` 2.37.0, `google-genai` 1.74.0, `httpx` 0.28.1,
`tenacity` 9.1.4). Then repoint the hardcoded interpreter path
`/Users/stevemorin/c/doxa-research/.venv/bin/python` in these files:

- `scripts/test-doxa-no-retry.py` (the `DOXA_PYTHON` default; it also honours the
  `DOXA_PYTHON` environment variable, so exporting that is enough to run the tests)
- `docs/planning/p02/paid-envelope.md` and `docs/superpowers/plans/2026-09-05-p02-research-execution.md`
  (the documented invocation lines)

`docs/planning/p02/tool-readiness.md` and `PROPOSAL.md` also contain the path,
but as dated inspection records; leave those as history. Confirm the wrapper
works before any paid call:

```bash
<doxa-venv>/bin/python scripts/doxa_no_retry.py --verify --json
# expect: patched true, openai_sdk_max_retries 0, every tenacity attempt count 1,
#         responses_create_shim true, background_model_gpt_5_6_sol true
```

**Linux virtual machine.** The Linux legs ran in a Lima instance named `ubuntu`,
Ubuntu 25.10 on aarch64, 8 CPUs and 16 GiB, with the home directory mounted so
the repository is visible at the same absolute path. Recreate and provision it:

```bash
limactl create --name=ubuntu template://ubuntu-25.10 && limactl start ubuntu
limactl shell ubuntu -- bash -lc 'curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
  source $HOME/.cargo/env && rustup toolchain install 1.96.0 --profile minimal
  sudo apt-get update -qq && sudo apt-get install -y -qq build-essential git pkg-config'
```

Workers invoke it as `limactl shell ubuntu -- bash -lc '<command>'`. Record in
every decision that the virtual machine is aarch64 while GitHub's
`ubuntu-latest` runners are x86_64.

**Pinned source repositories.** Research and the derived port documents read
these two trees by commit, never by checkout state, so the clones simply need to
contain the objects:

- `py-launch-blueprint` containing `b08bccfb55d05f15e46a83b52c5660b1881d19f5`
- `ts-launch-blueprint` containing `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`

`scripts/derive-port-docs.py` expects them at `~/c/py-launch-blueprint` and
`~/c/ts-launch-blueprint`; adjust its `REPOS` mapping if yours differ.

**Environment.** Export `OPENAI_API_KEY`, `PERPLEXITY_API_KEY`, `GEMINI_API_KEY`
and `ANTHROPIC_API_KEY`. Never print or commit their values; the tools resolve
them by name and the readiness records only ever list resolution state.

## 👉 First action

1. The three blockers are cleared as of 2026-09-08; confirm nothing has lapsed since.
2. Run the verification block under "Where you are" and confirm it is green.
3. Dispatch R06's synthesis (it is the only item whose reports are complete and
   whose decision is unwritten), and in parallel start Opus research for the
   Focused items that have only their Codex report: R07, R15, R16, R17, R19,
   R20, R21, R26, R33, R34, R43, R45, R63, R64, R65, R81, R85.
4. Once Doxa can submit, run the R38 pilot's third engine first, since the
   runbook makes the pilot the gate for bulk paid research.

## ℹ How this was made

Composed 2026-09-07 by Claude Fable 5.1 in session
`session_013Dvsi7FhLemRfUyFSQi87A`, from the execution ledger, the run
manifests and the repository state. No transcript digest was used; the ledger
is the primary record. Self-contained: ✓.
