# Official capability references checked 2026-09-04

- [OpenAI Responses create reference](https://developers.openai.com/api/reference/cli/resources/responses/methods/create): `background`, `max-output-tokens`, and `max-tool-calls` are request parameters. This supports the source review's distinction between available API controls and Doxa's actual request payload.
- [Perplexity Create Async Chat Completion](https://docs.perplexity.ai/api-reference/async-sonar-post): the async endpoint returns a request id/status and documents `idempotency_key` as the unique key that prevents duplicate requests.
- [Perplexity Get Async Chat Completion](https://docs.perplexity.ai/api-reference/async-sonar-api-request-get): the persisted id is polled through the async GET endpoint; documented statuses include `CREATED`, `IN_PROGRESS`, `COMPLETED`, and `FAILED`.
- [Google Gemini Deep Research agent](https://ai.google.dev/gemini-api/docs/deep-research): Deep Research uses the Interactions API, requires background execution, and is polled by interaction id. The page identifies `deep-research-preview-04-2026` as a Deep Research agent id.
- [Google Gemini background execution](https://ai.google.dev/gemini-api/docs/background-execution): background interactions return an id for polling/reconnect and document `cancel` for running interactions.

The live pages are capability references only. No API request was made from this inspection.
