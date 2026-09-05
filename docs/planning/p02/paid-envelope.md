# Paid execution envelope — R38 pilot (prepared 2026-09-04)

Status: prepared for owner approval. No paid Doxa request has been submitted.
This document proposes the boundary for the first paid batch; it does not set
one. Operation counts, tool-call caps and timeouts bound work, not dollars.
Only provider-side limits or the owner's approved figure bound spend.

## The operation

One Doxa `all_deep_research` operation for the canonical R38 prompt
(`research/topics/38-commit-message-linter/prompts/commit-message-linter.prompt.md`),
launched through the retry-isolation wrapper so each provider receives
exactly one create attempt:

```bash
/Users/stevemorin/c/doxa-research/.venv/bin/python scripts/doxa_no_retry.py \
  --config docs/planning/p02/doxa-pilot.config.toml \
  ask --mode all_deep_research \
  --prompt-file research/runs/R38/<run-id>/inputs/prompt.md \
  --output-dir research/runs/R38/<run-id>/doxa \
  --combined --async --json
```

| Provider | Model (builtin mode) | Jobs | Cost lever inside Doxa | Enforceable ceiling |
|---|---|---|---|---|
| OpenAI | `o3-deep-research` | 1 | `max_tool_calls = 80`, `code_interpreter = false` (pilot config) | Project hard spend limit set by the owner in the OpenAI dashboard |
| Perplexity | `sonar-deep-research` | 1 | none | Prepaid credit balance with auto top-up disabled |
| Gemini | `deep-research-preview-04-2026` | 1 | none (60-minute agent maximum) | AI Studio project spend cap set by the owner |

The wrapper makes the create count deterministic: at most three provider jobs
per operation, and zero automatic resubmission after an ambiguous failure
(`scripts/doxa_no_retry.py --verify` shows one attempt per submit wrapper and
`max_retries = 0` on the OpenAI SDK; the unpatched defaults are three tenacity
attempts stacked on two SDK retries). Recovery of a slow or partial operation
uses `doxa status <op>` and `doxa resume <op>`, which reconnect to the recorded
provider job IDs and create nothing.

## Price references (retrieved 2026-09-04)

| Provider | Published price | Source |
|---|---|---|
| OpenAI `o3-deep-research` | $10 / 1M input tokens, $2.50 / 1M cached input, $40 / 1M output; 200k context, 100k max output | https://developers.openai.com/api/docs/models/o3-deep-research |
| OpenAI built-in tools | Web search $10.00 / 1k calls plus search content tokens at model rates; hosted code interpreter $0.03–$1.92 per 20-minute container session (disabled for the pilot) | https://developers.openai.com/api/docs/pricing |
| Perplexity `sonar-deep-research` | $2 / 1M input, $8 / 1M output, $2 / 1M citation tokens, $3 / 1M reasoning tokens, $5 / 1k searches; no per-request fee | https://docs.perplexity.ai/getting-started/pricing |
| Gemini Deep Research (`deep-research-preview-04-2026`) | Billed at the underlying model's standard rates plus tool fees; Google's own estimate "~$1.00 – $3.00 per task" (preview rates, subject to change) | https://ai.google.dev/gemini-api/docs/deep-research and https://ai.google.dev/gemini-api/docs/pricing |

## Estimate for one operation (assumptions stated; not a ceiling)

| Provider | Assumed usage | Estimated cost |
|---|---|---|
| OpenAI | 100k–400k input tokens across the agent loop (the prompt is ~6k tokens and requires crates.io and GitHub API figures), 15k–40k output tokens, 40–80 web-search calls | $2.6 – $6.4 |
| Perplexity | 20k input, 10k output, 30k citation, 60k reasoning tokens, 30–60 searches | $0.5 – $1.5 (Doxa's mode description quotes an approximate $1.32 per query) |
| Gemini | one task within the 60-minute agent maximum | $1 – $3 (Google's estimate) |
| **Total** | | **$4 – $11 per operation** |

Uncertainty: OpenAI's agent loop length is the dominant variable; the
`max_tool_calls = 80` cap bounds search calls but not per-call content tokens.
A retry of the OpenAI or Gemini job after a failure is a second job with the
same estimate. These figures are planning estimates from published list prices,
not an invoiced spend assertion.

## Enforceable limits the owner can set before approval

- **OpenAI (hard cap exists).** Project settings → Limits → Spend → Edit spend
  limit → enter the monthly amount → turn on "Enforce a hard limit" → Save.
  Requests then fail with HTTP 429 `project_spend_limit_exceeded`; enforcement
  is "not instantaneous, so recorded spend can slightly exceed the configured
  amount" (https://developers.openai.com/api/docs/guides/spend-limits,
  2026-09-04). The same control exists at organization level and through the
  Admin API (https://developers.openai.com/api/docs/guides/admin-apis).
- **Gemini (hard cap exists, with latency).** AI Studio project-level spend cap;
  "Long-running tasks like batch mode completions and agent sessions may incur
  overages beyond your project spend cap" because billing lags by about ten
  minutes (https://ai.google.dev/gemini-api/docs/billing, 2026-09-04). Billing
  account tiers also pause service at the tier maximum.
- **Perplexity (no cap feature found).** The API is prepaid credits with
  optional auto top-up (https://docs.perplexity.ai/docs/getting-started/projects,
  2026-09-04). Leaving auto top-up disabled makes the remaining balance the
  ceiling. Perplexity's list endpoint
  (`GET https://api.perplexity.ai/async/chat/completions`) allows inventory
  reconciliation after an ambiguous failure; OpenAI and Gemini expose no
  list-responses or list-interactions endpoint, which is why their create
  retries are disabled rather than reconciled.

## Options for the owner

| Option | What it means | Consequence |
|---|---|---|
| **A. Provider caps plus an approved figure (recommended)** | Owner sets the OpenAI project hard limit and the Gemini project cap, confirms the Perplexity balance and auto top-up state, and approves a maximum authorized spend for the pilot batch | Dollar exposure is bounded by the caps even if the estimate is wrong; the runner records the figure as `--budget` and the approval as `--authorization-ref` |
| B. Job-count boundary with variable cost | Owner approves exactly one operation (three provider jobs, single attempt each) without provider caps | Exposure is bounded only by the estimate's accuracy; a long OpenAI agent loop could exceed it |
| C. Defer Doxa; run R38 on Codex and Opus only | Pilot proceeds with two engines | Violates the approved three-engine pilot (amendment A6) and needs an owner downgrade decision |

Recommendation: A, with a pilot figure of USD 40 across the three providers
(about four times the upper estimate), OpenAI project hard limit and Gemini
project cap each at or below that figure, and Perplexity auto top-up off.

## Exact approval needed

Reply with: (1) the maximum authorized spend for batch `B0-R38` in USD;
(2) confirmation that the OpenAI hard limit, the Gemini project cap and the
Perplexity auto top-up state are set as intended; (3) the retry policy
(recommended: no automatic retry; a failed provider job is re-approved
individually); and (4) an authorization reference string to record with
`research_runner.py run prepare --authorization-ref`.
