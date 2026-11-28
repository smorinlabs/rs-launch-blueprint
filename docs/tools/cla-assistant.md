# CLA Assistant

[CLA Assistant](https://cla-assistant.io) is a hosted service that automates
Contributor License Agreement checks on GitHub pull requests (`F208`).

## How It Works

1. Maintainers link a CLA document Gist (derived from
   [individual-cla.md](../contributing/cla/individual-cla.md) and
   [corporate-cla.md](../contributing/cla/corporate-cla.md)) in the
   [CLA Assistant dashboard](https://cla-assistant.io). See
   [Setting Up CLA Assistant](../contributing/cla/cla-setup-guide.md).
2. On a pull request from a first-time contributor, the bot prompts for a
   one-time signature and updates the commit status once signed.
3. Bot accounts (`*[bot]`) are exempted in repository CLA settings so automated
   release and dependency PRs stay unblocked.

## Sunset Contingency (`F208`)

The hosted `cla-assistant.io` service is the primary option; the older
self-hosted `contributor-assistant/github-action` repository is archived
upstream. If the hosted service ever becomes unavailable, downstream projects
have two clean contingencies:

- **Switch to a Developer Certificate of Origin (DCO):** enforce `Signed-off-by:`
  commit trailers via GitHub's DCO check with zero third-party CLA hosting.
- **Maintain an internal fork** of the archived action if a signed CLA remains a
  legal requirement.

See [CLA FAQ](../contributing/cla-faq.md) for contributor-facing answers.
