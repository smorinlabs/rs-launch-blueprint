# Setting Up CLA Assistant with GitHub

This guide explains how maintainers optionally enable
[cla-assistant.io](https://cla-assistant.io) on a GitHub repository.

## 1. Publish the CLA Gist

1. Sign in to GitHub and create a new Gist containing `CLA.md` with your
   project's individual and corporate CLA terms (starting from
   [individual-cla.md](individual-cla.md) and [corporate-cla.md](corporate-cla.md)).
2. Copy the raw URL of `CLA.md`.

## 2. Link the Repository in CLA Assistant

1. Sign in at [cla-assistant.io](https://cla-assistant.io) with GitHub.
2. Select **Configure CLA**, choose the target repository, and paste the raw
   Gist URL.
3. Under exempt usernames/patterns, add `*[bot]` so automated PRs (such as
   Dependabot and Release Please) are never blocked waiting for a CLA signature.
4. Save the configuration.

## 3. Verify on a Pull Request

Open a test pull request from an unsigned account to confirm CLA Assistant
comments with a signing link, updates the check to passing once signed, and
skips prompting on subsequent PRs from the same account.
