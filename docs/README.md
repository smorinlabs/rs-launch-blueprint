# Documentation Orientation Map

Welcome to the `rs-launch-blueprint` documentation corpus. The same
CommonMark/GFM source tree under `docs/` renders natively on GitHub **and**
builds with `mdbook 0.5.4` (`book.toml`) into the hosted GitHub Pages site
(`R81`).

Use [SUMMARY.md](SUMMARY.md) as the single authoritative table of contents for
every section and page.

## Corpus Organization (`F342`)

User-facing and contributor documentation is organized into six Diátaxis
categories:

| Directory       | Audience & Intent                                                                               |
| --------------- | ----------------------------------------------------------------------------------------------- |
| `about/`        | Architecture overview and the full `R01`–`R86` design-decision index.                           |
| `tutorials/`    | Guided end-to-end onboarding from clean clone to running CLI, web, and stamping.                |
| `tasks/`        | Task-focused how-to guides (dev loop, config/secrets/logging, testing, CI/CD, troubleshooting). |
| `reference/`    | Exact CLI grammar, web HTTP API reference, error catalogs, and workspace layout.                |
| `tools/`        | Deep dives into Blaze acceleration, `bacon`, and the pinned quality toolchain.                  |
| `contributing/` | Pull request workflow, Conventional Commits, review triggers, and community rules.              |

Operational guides at the top of `docs/` support day-one setup and releases:

- [Project Setup Checklist](PROJECT_SETUP.md) — human-only GitHub, crates.io, GHCR, and Pages setup
- [Post-Initialization Notes](POST_INIT.md) — immediate steps after Template Press completes
- [Release Process](RELEASE.md) — Release Please, `cargo-dist`, crates.io, and GHCR publishing
- [Bootstrap Skill Guide](skills/new-rust-project.md) — `new-rust-project` project and global install
- [Documentation Authoring Guide](docs.md) — dialect rules, adding pages, link checks, and upgrade path

## Engineering Records (`F354`–`F357`)

Because `book.toml` sets `[book] src = "docs"`, the three engineering-record
buckets live under `docs/` and are explicitly listed in the **Engineering
Records** suffix section of [SUMMARY.md](SUMMARY.md) so they build and link-check
alongside the narrative documentation:

| Directory   | Holds                                                                | Normative?       |
| ----------- | -------------------------------------------------------------------- | ---------------- |
| `adr/`      | **Architecture Decision Records** — immutable single-decision logs.  | Yes (decision)   |
| `design/`   | **Design Specifications** — normative behavior and convention specs. | Yes (plan)       |
| `research/` | **Research Notes** — exploratory comparisons and benchmark findings. | No (exploration) |

Rule of thumb: exploring options goes in `research/`, specifying behavior goes
in `design/`, and locking a single decision goes in `adr/`.

## Local Commands

```bash
just docs-build    # Build static HTML site into book/ (mdbook build)
just docs-dev      # Serve locally with live reload (mdbook serve --open)
just docs-check    # Verify all offline Markdown links (lychee --offline)
just docs-api      # Build workspace rustdoc API reference with -D warnings
```
