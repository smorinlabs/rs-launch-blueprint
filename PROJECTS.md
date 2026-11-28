# Projects

Index of every project in this repo. Per-project files live in
`projects/`. Skills in the `project-harness` plugin operate on this
file plus those.

## Status legend

| Glyph | Meaning                | File state                          |
| ----- | ---------------------- | ----------------------------------- |
| `[?]` | Idea / exploratory     | stub file, trailing-hyphen filename |
| `[ ]` | Scoped, not started    | full scope + tasks                  |
| `[~]` | In progress            | full + some `[x]` tasks             |
| `[x]` | Completed              | all tasks `[x]`                     |
| `[-]` | Decided not to do      | reason at top of file               |
| `[>]` | Proceeded to successor | redirects to successor's file       |

## Conventions

- Filename: `projects/P<NN>-<kebab-slug>.md` for scoped/active/done;
  `projects/P<NN>-<roughName>-.md` (trailing hyphen) for ideas.
- Trunk row: `- [<glyph>] **P<NN>** — [<title>](projects/<filename>)`.
  The title is a standard markdown link to the per-project file —
  external tools (markdown linters, doc generators, AI agents
  reading the repo without project-harness loaded) can parse the
  schema without prior knowledge of the conventions.
- Every non-`[?]` per-project file has a `**References**` block at
  the top whose first bullet is `- **Trunk:** [PROJECTS.md](../PROJECTS.md)`,
  the back-pointer to this file. Bidirectional schema.
- One trunk row per file; one file per trunk row.
- Status glyph mirrors the rolled-up state of the per-project file.
- Flip task checkboxes immediately as each task lands (no batching).
- TDD bias: every project has at least one `TS` task before its first
  `T` task. Opt out with `**TDD: not applicable**` in the body.

Planning system: **Superpowers** — specs/plans live under
`docs/superpowers/specs/` and `docs/superpowers/plans/`. Per-project
`**References**` blocks point there.

### Project workflow skills (plugin: project-harness)

- `using-project-harness` — bootstrap: when to use which skill below
- `project-next` — orient: what's in progress, what's next, what's recently touched
- `project-add` — capture an idea (≤4 questions, reserves the ID with a commit)
- `project-refine` — flesh out / scope / decompose an existing project
- `project-audit` — verify state matches conventions; fix per finding

## Project index

<!-- One row per project. Scoped / in-progress / done first; ideas last. -->

- [x] **P01** — [Port research program](projects/P01-port-research-program.md) — evidence-based research tree, commonality ledger, and deep-research prompts (v0.1.0)
- [x] **P02** — [Execute research program](projects/P02-execute-research-program.md) — run accepted research items to audited decisions and filled parameters (v0.2.0)
- [x] **P03** — [Install difftree-action PR comment workflow](projects/P03-install-difftree-action-pr-comment-workflow.md) — scaffold canonical difftree-pr-comment.yml via difftree-action-setup
- [x] **P04** — [Workspace skeleton toolchain and Blaze accelerator](projects/P04-workspace-skeleton-toolchain-and-blaze-accelerator.md) — 4-crate Cargo workspace, Edition 2024, MSRV, Makefile/Justfile, and opt-in Blaze local loop
- [x] **P05** — [Local quality gates hooks and devcontainer](projects/P05-local-quality-gates-hooks-and-devcontainer.md) — lefthook, committed, gitleaks, dprint, ast-grep, large-file guard, DevContainer, and AI config
- [x] **P06** — [Core library ports config and logging](projects/P06-core-library-ports-config-and-logging.md) — ProjectsPort/Service, ureq adapter, RSLB errors, XDG paths, 6-tier TOML config, secrets, and tracing
- [x] **P07** — [CLI rslbp feature parity and test harness](projects/P07-cli-rslbp-feature-parity-and-test-harness.md) — clap derive CLI, output formats, rich UX, nextest, proptest, insta, assert_cmd, and llvm-cov
- [x] **P08** — [Optional web service core and middleware](projects/P08-optional-web-service-core-and-middleware.md) — opt-in web feature, axum/tokio rslbp-serve, RFC 9457, /v1, pagination, idempotency, rate limit, probes
- [x] **P09** — [OpenAPI contracts observability and container image](projects/P09-openapi-contracts-observability-and-container-image.md) — utoipa snapshot, oasdiff, client gen, otel, Prometheus metrics, Dockerfile, and Blaze re-probe
- [x] **P10** — [GitHub Actions CI security and AI workflows](projects/P10-github-actions-ci-security-and-ai-workflows.md) — plan-gated ci.yml, ci-ok, dep-audit, CodeQL, TruffleHog, canary, Claude, Codex, and Muse audit-triage
- [x] **P11** — [Release automation binary distribution and packaging](projects/P11-release-automation-binary-distribution-and-packaging.md) — release-please rust, cargo-dist binaries, packed-crate guards, semver-checks, and GHCR publish
- [x] **P12** — [Template Press bootstrap skill and community files](projects/P12-template-press-bootstrap-skill-and-community-files.md) — template-press 4.1+, global new-rust-project skill, bootstrap acceptance, and contributors/community docs
- [ ] **P13** — [Documentation corpus examples and final parity audit](projects/P13-documentation-corpus-examples-and-final-parity-audit.md) — mdBook GitHub Pages corpus, lychee/rustdoc gates, EXAMPLECLI/EXAMPLEWEB, and full parity audit
