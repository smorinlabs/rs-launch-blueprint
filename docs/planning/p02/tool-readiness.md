# P02 execution-tool readiness

Inspection date: 2026-09-04. The inspected research worktree is
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan` at
`2f3569051af2c2089f60f6cad129bc6e55482c30`. This report records readiness
only. No Doxa research operation was submitted. Root executed two bounded
Claude inference probes, whose results appear below.

The exact command outputs are in
[`evidence/readiness-commands.txt`](evidence/readiness-commands.txt). The
source trace is in [`evidence/readiness-source.txt`](evidence/readiness-source.txt),
and official capability links are in
[`evidence/readiness-official-links.md`](evidence/readiness-official-links.md).

| Engine/provider | Installed and version | Auth check | Model access test | Network and output location | Concurrency and async behavior | Remaining gap |
|---|---|---|---|---|---|---|
| Claude Opus | `/Users/stevemorin/.local/bin/claude`, `2.1.261` | `claude auth status` reported `loggedIn: false`, `authMethod: none` | Root's bounded nonce probe succeeded with result model `claude-opus-5`; raw evidence is `probes/claude-opus.json` | Probe used isolated JSON output; no research output directory | Claude is the runbook engine capped at four Claude subagents; probe was synchronous and completed | Persistent auth state and real research-prompt execution remain unverified. Reported list cost was `$0.024439`, including a Haiku helper; this is not an invoiced spend assertion |
| Claude Fable | Same Claude CLI and version | Same local status result | Root's bounded nonce probe succeeded with result model `claude-fable-5-1`; raw evidence is `probes/claude-fable.json` | Probe used isolated JSON output; no research output directory | Same four-Claude runbook cap; probe was synchronous and completed | Persistent auth state and real research-prompt execution remain unverified. Reported list cost was `$0.047979`, including a Haiku helper |
| Codex companion | Companion source exists at `/Users/stevemorin/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs`; local CLI `/Users/stevemorin/.local/bin/codex`, `codex-cli 0.142.5` | `codex login status` reported `Logged in using ChatGPT` | This inspection completed successfully as a Luna runtime probe; it did not run a Codex companion job or prove access to embedded model names | Companion runbook paths are `raw/codex-<YYYY-MM-DD>.md`; none created here | Companion supports background task jobs plus status/result/cancel; out-of-process jobs do not consume the runbook's four-Claude cap | The companion defines only `spark -> gpt-5.3-codex-spark`; host-advertised `gpt-5.6-terra` and `gpt-5.6-luna` are not aliases. Model access and raw-job lifecycle remain untested |
| Doxa/OpenAI | Direct executable `/Users/stevemorin/c/doxa-research/.venv/bin/doxa`; reports `Doxa Research v3.1.2`; source `pyproject.toml` declares `3.2.0` | Isolated `providers check --json` returned missing `openai`; this check tests local key presence, not API authentication | Not tested; no key was supplied and no endpoint was contacted | Default source config reports `./research-outputs`; recommended runbook destination is one dedicated `research/topics/<item>/doxa/<prompt-stem>/` | `all_deep_research` is background. Doxa submits provider jobs sequentially, then polls remote jobs; `--async` persists IDs and exits | Need current package/version convergence, credentials, model-access check, and a hard spend control. Doxa sends optional `max_tool_calls` only when configured and has no default output-token or cost cap |
| Doxa/Perplexity | Same Doxa executable/version | Isolated `providers check --json` returned missing `perplexity`; local key presence only | Not tested; no endpoint was contacted | Same dedicated per-prompt Doxa directory; Perplexity results are saved as provider files | Background async Sonar uses POST then GET polling. Doxa generates one idempotency key and reuses it across submission retries | Built-in mode uses `sonar-deep-research` with `reasoning_effort=high` and an approximate `$1.32/query` description, but no hard ceiling. Credentials, access and current model support remain unverified |
| Doxa/Gemini | Same Doxa executable/version | Isolated `providers check --json` returned missing `gemini`; local key presence only | Not tested; no endpoint was contacted | Same dedicated per-prompt Doxa directory; Gemini results are saved as provider files | Background Interactions API job is submitted with an interaction ID, then polled/reconnected; Doxa's create retry has no idempotency key | Built-in model `deep-research-preview-04-2026` and access remain unverified. Doxa's DR request sends no token or cost ceiling |

`providers check` is not an authentication gate. Its implementation reads
configured `api_key` values and `${VAR}` environment placeholders in
`src/doxa_research/commands.py:867-879`; it does not instantiate providers or
contact OpenAI, Perplexity, or Google. The JSON command returned process exit
`0` while its data reported `complete: false`, so the readiness wrapper must
inspect the data object rather than exit status alone.

The installed Doxa executable is usable by its absolute path. It imports the
local editable source at commit `ba423be7e96461962ae0fde21373e5e10aeecae2`,
whose project version is `3.2.0`, while stale installed package metadata reports
`3.1.2`. Record both source and metadata; select a reproducible package/source
and dependency pin before binding execution. This routine version reconciliation
does not itself require an owner decision. This inspection did not install or
update anything. `uv tool list` was blocked by permission to shared
`~/.cache/uv`; no `uvx` download was attempted.

Runtime key resolution is `CLI > environment > config` in
`src/doxa_research/providers/__init__.py:50-76`. The bounded filesystem check
found no `.env` files in the Doxa source checkout or inspected research
worktree. It found Doxa config files under the user config and application
support directories. The initial isolated probe used empty XDG configuration
and state directories, so it did not establish normal credential readiness.
Root subsequently ran the normal configuration check from the research
checkout: `/Users/stevemorin/.config/doxa/doxa.config.toml` exists, no project
override loads, the relevant environment variables are absent, and all three
providers are still missing. Root also resolved provider fields from the legacy
`/Users/stevemorin/Library/Application Support/doxa/config.toml` in memory:
OpenAI, Perplexity and Gemini are all missing or unresolved placeholders.
Only resolution states were printed; key values were never logged or copied.
The owner was asked for an existing alternative credential source path.

The `all_deep_research` mode is a three-provider fan-out:

| Provider | Mode model | Provider job count for one approved pilot prompt |
|---|---|---:|
| OpenAI | `o3-deep-research` | 1 |
| Perplexity | `sonar-deep-research` | 1 |
| Gemini | `deep-research-preview-04-2026` | 1 |
| Local combined output | concatenation of completed provider files | 0 provider jobs |

Actual count from this inspection: OpenAI `0`, Perplexity `0`, Gemini `0`,
combined reports `0`. The recommended first Doxa pilot is exactly one approved
prompt in one dedicated output directory, submitted as one background Doxa
operation with `--combined --async --json`. That requests three initial paid
provider jobs and one local combined file. It does not establish a maximum:
automatic create retries can duplicate OpenAI/Gemini jobs. Resolve those retries
before paid submission. Do not submit a second operation to
recover a slow or partial run; use the recorded operation ID with
`status`/`resume`.

The pilot has no application-level hard spend ceiling. `max_wait=30` minutes,
`retry_attempts=3`, and `max_transient_errors=5` bound waiting and retry policy,
not dollars. OpenAI's API supports `max-output-tokens` and `max-tool-calls`, but
Doxa's deep-research request sends only optional `max_tool_calls`, with no
configured default. Perplexity's approximate per-query price is informational,
and Gemini's deep-research request has no token or cost limit in Doxa. Paid
execution needs a concrete approved envelope: either an enforceable provider
spending limit, or an explicitly approved job-count boundary with variable cost.
If the owner requires a hard dollar limit and none can be enforced, the paid
test stays blocked. The current readiness request is not paid-run approval.

Recovery is safe only when the operation ID is retained. Doxa persists each
submitted provider job ID; `resume` reconnects to those IDs and does not create
new jobs. A normal mixed result can finish with successful files plus recorded
provider failures, while `resume --async` performs one status check per
non-completed provider and marks the aggregate complete only when every
provider is complete. OpenAI and Gemini submit retries can still duplicate a
paid job after an ambiguous timeout because their create calls have no
idempotency key. Perplexity's async retry uses one stable idempotency key, so
that provider has a stronger duplicate-creation guard.

The Codex companion and both cached copies of `superpowers:writing-plans` are
available. Their exact paths and the model-alias limitation are recorded in
[`evidence/readiness-tooling.md`](evidence/readiness-tooling.md). The execution
host advertises `gpt-6-astra`, `gpt-5.6-terra`, `gpt-5.6-luna`, and four total
concurrent agents including root. That host limit is distinct from the
runbook's four-Claude-subagent limit; Doxa and Codex remain out of process.

Official API references checked for the capability statements are the [OpenAI
Responses create reference](https://developers.openai.com/api/reference/cli/resources/responses/methods/create),
[Perplexity async create reference](https://docs.perplexity.ai/api-reference/async-sonar-post),
[Perplexity async get reference](https://docs.perplexity.ai/api-reference/async-sonar-api-request-get),
and Google's [Gemini Deep Research guide](https://ai.google.dev/gemini-api/docs/deep-research)
and [background execution guide](https://ai.google.dev/gemini-api/docs/background-execution).
