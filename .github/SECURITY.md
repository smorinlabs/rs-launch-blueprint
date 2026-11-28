# Security Policy

This security policy applies to `smorinlabs/rs-launch-blueprint`. Projects
stamped from this template receive a clean starter security policy via
`press/stubs/security.md` and should maintain their own reporting process.

## Supported Versions

Security updates are applied to the latest state of `main` and the most recent
tagged release.

## Reporting a Vulnerability

Please report security vulnerabilities privately rather than opening a public
GitHub issue:

1. Use GitHub's **Report a vulnerability** button under **Security -> Advisories**
   (Private Vulnerability Reporting), or
2. Email the maintainer at `steve.morin@gmail.com`.

Please include reproduction steps, affected versions or commits, and estimated
impact. We aim to acknowledge reports within 72 hours and coordinate a fix
before public disclosure.

## Security Controls

- **Static analysis:** CodeQL (`.github/workflows/codeql.yml`) and `ast-grep`
  security rules (`just security`)
- **Supply-chain & dependency audits:** `cargo-audit`, `cargo-deny`,
  OSV-Scanner, and GitHub Dependency Review
- **Secret scanning:** `gitleaks` (pre-commit and CI) and TruffleHog
- **Workflow hardening:** `zizmor`, `actionlint`, least-privilege `permissions`,
  and SHA-pinned third-party actions

## Code Scanning Setup

This repository runs CodeQL explicitly via `.github/workflows/codeql.yml`.
Disable GitHub's built-in default CodeQL setup to prevent duplicate or
conflicting runs:

```bash
gh api --method PATCH "repos/smorinlabs/rs-launch-blueprint/code-scanning/default-setup" \
  -f state=not-configured
```
