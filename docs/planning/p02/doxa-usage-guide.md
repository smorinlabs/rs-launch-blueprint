# Using Doxa Research for P02 paid runs

Operational guidance, written 2026-09-08 after exercising all three
deep-research engines end to end. Command record:
[`probes/provider-verification-2026-09-08.txt`](probes/provider-verification-2026-09-08.txt).

## The one rule

**Every paid Doxa call goes through `scripts/doxa_no_retry.py`. Never call
`doxa` directly for research.**

```bash
<doxa-venv>/bin/python scripts/doxa_no_retry.py \
  --config docs/planning/p02/doxa-pilot.config.toml \
  ask --mode all_deep_research \
  --prompt-file research/runs/R##/<run-id>/inputs/prompt.md \
  --output-dir research/runs/R##/<run-id>/doxa \
  --combined --async --json
```

Unpatched, Doxa stacks three tenacity attempts on two OpenAI SDK retries with
no idempotency key on OpenAI or Gemini, so an ambiguous timeout can create a
duplicate paid job that no list endpoint can reconcile. The launcher reduces
every provider to a single create attempt. Confirm before a batch:

```bash
<doxa-venv>/bin/python scripts/doxa_no_retry.py --verify --json
# expect: patched true · openai_sdk_max_retries 0 · every tenacity attempt 1
#         responses_create_shim true · background_model_gpt_5_6_sol true
```

## Environment

The shared environment is `/Users/stevemorin/c/doxa-research/.venv`, an
editable install of that repository's `main`. As of 2026-09-08 it carries
**google-genai 2.22.0** and **doxa-research 3.2.0**. Anything below
google-genai 2.0.0 fails every Gemini deep-research call with HTTP 400,
because Google retired the legacy Interactions schema; that floor was fixed
upstream in doxa-research PR #146. After pulling that repository, re-run
`uv sync` there or the venv keeps the old SDK.

## The three engines

| Provider | Model | Typical latency | Cost for a trivial question | Cost lever |
|---|---|---:|---|---|
| OpenAI | `gpt-5.6-sol` | ~17 s | ~USD 0.03 | `max_tool_calls` |
| Perplexity | `sonar-deep-research` | ~1 min | USD 0.329 at `reasoning_effort=low` | `reasoning_effort` |
| Gemini | `deep-research-preview-04-2026` | ~7 min | not self-reported | none in Doxa |

`o3-deep-research` and `o4-mini-deep-research` were shut down on 2026-07-23.
Doxa's builtin modes still name `o3-deep-research`, so the pilot config must
pin `gpt-5.6-sol`. That model carries no `deep-research` substring, so Doxa
alone would send it with no tools and an unsupported `temperature`; the
launcher's shim fixes both and forces background mode.

**Real prompts cost more than these figures.** They are one-sentence questions.
Perplexity's cost is dominated by searches, not answer length: 40 search
queries at USD 0.20 and 39,751 reasoning tokens at USD 0.119, against a
28-token answer. `max_tokens` caps only the visible completion. The builtin
default is `reasoning_effort=high`, which Doxa documents at about USD 1.32 per
query, so the setting is worth roughly 4x but never stops the search loop.

## Configuration: where keys go

Registered native keys go **flat** in `[modes.<mode>.<provider>]`. The
framework validates them into a `provider_request` bucket and nests them
itself. A nested table of the same name is rejected:

```toml
[modes.all_deep_research.openai]
model = "gpt-5.6-sol"      # required: omitting it silently falls back to the
max_tool_calls = 80        # shut-down builtin, because the layer deep-merges
code_interpreter = false

[modes.all_deep_research.perplexity]
reasoning_effort = "low"   # flat, NOT [modes.all_deep_research.perplexity.perplexity]
```

`background` is rejected inside a provider namespace
(`Unsupported provider parameter`); the mode's `kind = "background"` plus the
shim already force it.

**The pilot config currently overrides only the OpenAI namespace**, so the
Perplexity leg would run at `high`. Decide deliberately whether to add
`reasoning_effort` before the first paid batch; research quality is the reason
to leave it high, and cost is the reason to lower it.

## Spending discipline

Approved ceilings: **USD 40** for pilot batch `B0-R38`, **USD 300** total for
the remaining Deep operations, authorization `OWNER-2026-09-05-P02-EXEC`.
Neither is enforced by any provider, so the controller enforces them.

- Perplexity returns an exact cost breakdown. After each collection, read it
  and add it to the ledger:
  `GET https://api.perplexity.ai/async/chat/completions/<request-id>` →
  `.response.usage.cost.total_cost`.
- OpenAI reports token usage per response:
  `GET https://api.openai.com/v1/responses/<id>` → `.usage`. Price it at
  USD 4 per 1M input and USD 20 per 1M output, plus USD 10 per 1k web searches.
- Gemini reports no per-call cost. Google's own estimate is USD 1 to 3 per
  task. Count operations.

Stop paid submissions when the recorded sum reaches the ceiling.

## Never resubmit on a timeout

One `all_deep_research` operation starts three provider jobs. If the local
wait expires the remote jobs keep running and keep billing. Recover by ID,
never by resubmitting:

```bash
doxa status <operation-id>     # or: doxa list --all --json
doxa resume <operation-id>     # reconnects to recorded job IDs, creates nothing
```

Gemini alone can take 60 minutes, so set `max_wait` accordingly or submit with
`--async` and collect later. Record the operation ID with
`research_runner.py run submitted` **before** waiting on anything.

## Prove access before spending

Both checks are free and create no job:

```bash
# OpenAI: empty input reaches parameter validation only.
# missing_required_parameter = the model resolves; model_not_found = it does not.
curl -sS https://api.openai.com/v1/responses -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"gpt-5.6-sol","input":[],"background":true,"tools":[{"type":"web_search"}]}'

# Gemini
curl -sS -o /dev/null -w '%{http_code}\n' -H "x-goog-api-key: $GEMINI_API_KEY" \
  https://generativelanguage.googleapis.com/v1beta/models/deep-research-preview-04-2026
```

Perplexity has no free probe. Its `GET /v1/models` lists only third-party
gateway models (`anthropic/*`, `google/*`) and no `sonar*` entry at all, so it
proves nothing about Sonar either way. Ignore it.

A key that authenticates is not a key that can buy: on 2026-09-05 every free
check passed while the real job failed on exhausted credits. Only a call that
bills distinguishes the two.
