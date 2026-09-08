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

## Re-inspection 2026-09-04 (second session; controller Claude Fable 5.1)

This section supersedes the gap column above where it records a verified
route. Commands ran from the worktree at commit `9b60bb5e` and later. No paid
research request was submitted; no key value was printed or copied.

| Route | Verified today | Evidence |
|---|---|---|
| Claude CLI | `claude auth status` now reports `loggedIn: true`, `authMethod: claude.ai`, `apiKeySource: ANTHROPIC_API_KEY` (variable name only). The earlier probes stand: `opus` resolved to `claude-opus-5`, `fable` to `claude-fable-5-1` | `probes/claude-opus.json`, `probes/claude-fable.json` |
| Codex CLI identity | Two installs exist: `/Users/stevemorin/.local/share/mise/installs/node/26.5.0/bin/codex` (codex-cli 0.153.2, first on PATH) and `/Users/stevemorin/.local/bin/codex` (0.142.5). The pilot pins the 0.153.2 path. `codex exec -m gpt-6-astra`, `-m gpt-5.6-terra` and `-m gpt-5.6-luna` all ran; the CLI header printed `model: <that id>` and `provider: openai` for each. The `--json` event stream carries no model field, and the models' self-reported names (`unknown`, `gpt-5`) are not identity evidence; a non-ephemeral run also stores `session_meta.model` under `~/.codex/sessions`. Record the header line or the session metadata, never the reply | `probes/codex-header-*.txt` |
| Codex network and tools | With `--sandbox workspace-write -c 'sandbox_workspace_write.network_access=true' -c 'approval_policy="never"'` and stdin closed (`< /dev/null`), a `gpt-5.6-luna` worker ran `curl` to `https://api.github.com/repos/actions/checkout` (HTTP 200) and reported a web-search tool named `web__run`. Without stdin closed, `codex exec` blocks on "Reading additional input from stdin..." indefinitely; two such probes were killed after 11 and 2.5 minutes. Research jobs must use this exact form and save `-o <last-message>` plus the `--json` event stream under the run directory. The companion script's background job lifecycle remains untested and is not used by the pilot | `probes/codex-network-gpt-5.6-luna.txt` |
| Doxa credentials | `providers check --json` returns `{"missing": [], "complete": true}` under the user configuration and under `docs/planning/p02/doxa-pilot.config.toml`; the resolved sources are the environment variables `OPENAI_API_KEY`, `PERPLEXITY_API_KEY` and `GEMINI_API_KEY` | command record in this section |
| Provider model visibility (free calls) | OpenAI `GET /v1/models/o3-deep-research` returned the model object; `GET /v1/models` lists `o3-deep-research`, `o4-mini-deep-research` and their dated variants. Gemini `GET /v1beta/models` lists `deep-research-preview-04-2026`, `deep-research-max-preview-04-2026` and `deep-research-pro-preview-12-2025`. Perplexity has no free model endpoint; its access stays unverified until the approved pilot | curl with the key from the environment; response bodies filtered to identifiers |
| Doxa reproducibility | Source `ba423be7e96461962ae0fde21373e5e10aeecae2` (clean tree; `pyproject.toml` 3.2.0; installed metadata 3.1.2), Python 3.11.14, openai 2.37.0, google-genai 1.74.0, httpx 0.28.1, tenacity 9.1.4; venv distribution fingerprint `bfc189fea2ff441eb464f0e424a1da229c29ad120d9e5f2f5e74439c3dbf1aa5` (59 distributions). The pilot records these values in its run manifest | `probes/doxa-no-retry-verify.json` (`versions`) |
| Create-retry isolation | Unpatched: Doxa wraps every provider submit in three tenacity attempts, the OpenAI SDK adds `DEFAULT_MAX_RETRIES = 2` and its `_idempotency_header` is `None` (keys are generated but never sent), google-genai defaults to one attempt, and Perplexity's stable idempotency key has documented purpose but undocumented deduplication semantics. `scripts/doxa_no_retry.py` rebinds all five submit wrappers to one attempt and forces `max_retries = 0`; `--verify` prints the effective values and `scripts/test-doxa-no-retry.py` (6 tests as of 2026-09-05) proves the patched and unpatched states differ | `probes/doxa-no-retry-verify.json` |
| Inventory reconciliation | `doxa list --all --json` before any P02 submission holds 781 checkpoints (445 queued, 245 completed, 60 cancelled, 15 running, 16 failed; newest 2026-05-23). The stale queued and running entries predate this program. A pilot operation is identified by its absence from this baseline. Perplexity exposes `GET https://api.perplexity.ai/async/chat/completions` for listing; OpenAI and Gemini expose no list endpoint for background responses or interactions | `probes/doxa-inventory-baseline-summary.json` |
| Spend controls | OpenAI project or organization hard limits (429 `project_spend_limit_exceeded`, not instantaneous), Gemini AI Studio project spend caps (about ten minutes of billing latency; agent sessions may overrun), Perplexity prepaid credits with optional auto top-up and no cap feature. The pilot's estimate, the levers and the exact approval needed are in [paid-envelope.md](paid-envelope.md) | that file's dated references |
| Deep-research model availability | 2026-09-05: this supersedes the OpenAI finding in the "Provider model visibility (free calls)" row above and every `o3-deep-research` mention earlier in this document. OpenAI's `GET /v1/models` still lists `o3-deep-research` and `o4-mini-deep-research`, but both were shut down on 2026-07-23 (announced 2026-04-22), so the list endpoint is not an access check. The correct check is the job-free Responses validation probe (`POST /v1/responses` with `"input": []`), which returned `missing_required_parameter` for `gpt-5.6-sol` — the request reached model validation — and `model_not_found` for `o3-deep-research`. The pilot therefore pins `gpt-5.6-sol`, the vendor-named replacement, in `docs/planning/p02/doxa-pilot.config.toml`, and reaches it through the `scripts/doxa_no_retry.py` shim: Doxa recognises a deep-research model only by the `deep-research` substring, so unpatched it would send `gpt-5.6-sol` with `tools: []` and an unsupported `temperature` | https://developers.openai.com/api/docs/deprecations and https://developers.openai.com/api/docs/models/gpt-5.6-sol (both retrieved 2026-09-05); `scripts/test-doxa-no-retry.py` (`test_replacement_model_is_treated_as_deep_research_when_patched`, `test_responses_create_shim_rewrites_gpt5_requests_only`); `docs/planning/p02/doxa-pilot.config.toml` (the pinned model and its comment) |

Remaining gaps after this re-inspection: the owner's spend approval with the
provider-side caps set; Perplexity access (first proven by the pilot itself);
the Codex companion background lifecycle (unused by the pilot); and the P01
`v0.1.0` tag gate, which precedes any binding research.

## Provider verification 2026-09-08 (fork session; controller Claude Opus 5)

The three billing failures recorded on 2026-09-05 are cleared. This is the
first evidence in this program that a Doxa provider call both authenticates and
bills: every previous check proved key presence or endpoint reachability only.
Full command record: [`probes/provider-verification-2026-09-08.txt`](probes/provider-verification-2026-09-08.txt).

| Provider | Trivial paid call | Result | What it proves |
|---|---|---|---|
| OpenAI | `openai_quick` / `gpt-4.1-mini` | returned `4`, operation `research-20260907-222313-47c596d076234da7` | auth and credits; the 2026-09-05 `credit_balance_exhausted` is cleared |
| Perplexity | `perplexity_quick` / `sonar` | returned `4` with sources, operation `research-20260907-222323-53cef2bdc18e4edb` | auth and quota; the 2026-09-05 `insufficient_quota` is cleared |
| Gemini | `gemini_quick` / `gemini-2.5-flash-lite` | returned `4`, operation `research-20260907-222326-fe90c651d34b4c6c` | auth and billing; Gemini had never been reached before |

`doxa providers check --json` now returns `{"missing": [], "complete": true}`,
and every call ran through `scripts/doxa_no_retry.py`, whose self-verify
reported one create attempt per provider and the `gpt-5.6-sol` shim active.

Pilot model access, probed without creating any job:

| Model | Probe | Result |
|---|---|---|
| `gpt-5.6-sol` | `POST /v1/responses` with an empty `input` | `missing_required_parameter`, so the model resolves: accessible |
| `o3-deep-research` | same | `model_not_found`, confirming the 2026-07-23 shutdown and the need for the shim |
| `deep-research-preview-04-2026` | `GET /v1beta/models/...` | HTTP 200: accessible |
| `sonar-deep-research` | none available | **not proven** |

Perplexity's `GET /v1/models` returns 49 third-party gateway models
(`anthropic/*`, `google/*`, `perplexity/deepseek-*`) and no `sonar*` entry at
all, while first-party `sonar` answered successfully. That catalog is therefore
not authoritative for Sonar, and `sonar-deep-research`'s absence from it is not
evidence. Perplexity offers no free probe for it, because any POST to
`/async/chat/completions` creates a billable job. Its access is first proven by
the R38 pilot itself, which remains the correct place to spend that money.
