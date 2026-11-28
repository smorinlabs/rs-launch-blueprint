# Security Policy

> Customize the supported versions and contact channel below for this project.

## Supported Versions

Security fixes are applied to the latest minor release on `main`.

## Reporting a Vulnerability

Please report suspected security vulnerabilities privately rather than opening a
public issue:

1. Use GitHub's **Report a vulnerability** button under the repository's
   **Security -> Advisories** tab (Private Vulnerability Reporting), or
2. Contact the maintainers listed in `Cargo.toml`.

Include reproduction steps, affected versions, and potential impact. Maintainers
aim to acknowledge reports within 72 hours and coordinate a fix before public
disclosure.

## Code Scanning Setup

This repository runs CodeQL via `.github/workflows/codeql.yml` rather than
GitHub's default setup. If GitHub's default CodeQL setup is enabled on the
repository, disable it so workflow runs do not conflict:

```bash
gh api --method PATCH "repos/{owner}/{repo}/code-scanning/default-setup" \
  -f state=not-configured
```
