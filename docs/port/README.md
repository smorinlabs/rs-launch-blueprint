# Port analysis — method and vocabulary

Produced per `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md`.

## How the files relate

1. `areas/<area>.md` — raw evidence. One file per area, each a side-by-side
   table of how `py-launch-blueprint` and `ts-launch-blueprint` handle every
   feature in that area, with file references and any `TS_PORT_DECISIONS.md`
   ids that explain a difference. Written by survey agents; **no verdicts**.
2. `COVERAGE.md` — every source file of both repos (`git ls-files`) mapped to
   the feature ids it contributed to, or `EXCLUDED: <reason>`. Proves no file
   was silently skipped by the survey (spec §6.4).
3. `COMMONALITY.md` — the authoritative ledger. One row per atomic feature,
   columns `ID · Feature · Area · Origin · Verdict · Item · Notes`; verdicts
   from the closed set below and legal for the row's origin. A pattern and the
   tool implementing it are separate rows: the tool row's Notes carry
   `parent: F###`. `REUSE` rows carry `rust-ok: yes` and `live: YYYY-MM`.
   `Item` is the `R##` for verdicts that need research, `—` otherwise.
   Override arguments live under `## Override arguments` as `### OV-nn`.
4. `PARAMETERS.md` — the shared-parameter registry, `param · kind · owner ·
   value · description`. `fixed` parameters are decided by the owner up front
   (`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, …);
   `researched` parameters are owned by exactly one `R##` (spec §6.3).
5. `DIVERGENCE-ANALYSIS.md` — Phase 3.5 input: for every research item, the
   py state, the ts state, why they differ (cause class A–G), the Rust
   question, and whether one value should serve all three repos
   (`harmonize`). Evidence base for the owner review's rationale column.
6. `OWNER-REVIEW.md` — Phase 3.5, one row per item: `item · disposition
   (accept | narrow | force | drop) · rationale · date`. Not waivable. Its
   *Owner direction* section binds the P02 research runs.
7. `REVIEW-PHASE4.md` — Phase 4, the independent reviewer's findings table
   verbatim, each row marked `fixed` or `accepted` with the reason.
8. `PY_INVENTORY.md`, `TS_INVENTORY.md` — per-repo views derived from the
   same rows, for reading one source repo end to end.
9. `../../research/CLAUDE.md` — every ledger row whose verdict needs research
   maps to an `R##` item with a prompt (several rows may share one `bundle`
   item). Columns: `id · slug · kind (crate | pattern | bundle) · origin ·
   verdict · owns · prompt · status (open | in-progress | resolved | dropped)`.
   `resolved` requires a non-empty `DECISION.md`, `audit-codex.md`, and
   `audit-fable.md`. `../../research/RUNBOOK.md` is the execution contract
   for the session that runs the prompts (spec §11);
   `../../research/PROMPT-TEMPLATE.md` is the eight-section prompt shape every
   `<slug>.prompt.md` follows.
10. `ts-research-method-review.md` — how the TypeScript port's research was
    actually run, what to copy, and what it got wrong; the source of the
    couplings rule, the owner review phase, and the audit files.

## Verdict vocabulary (closed set — enforced by `scripts/check-research-tree.sh`)

Origin (from the area tables): `same` · `different` · `py-only` · `ts-only` · `none`.

| Verdict | Legal origin | Meaning | Research item |
|---|---|---|---|
| `COMMON → REUSE` | `same` | Language-neutral; inherited unchanged (`rust-ok: yes`, `live:` in Notes) | none |
| `COMMON → SUBSTITUTE` | `same` | Same pattern; the tool is language-bound (`parent: F###` in Notes) | yes |
| `COMMON → OVERRIDE (OV-nn)` | `same` | A strong Rust-specific reason to change the *pattern* | yes — burden of proof on deviating |
| `ADOPT` | `py-only`, `ts-only` | One-sided precedent, language-neutral; taken as-is | none |
| `DIVERGENT` | `different`, `py-only`, `ts-only` | Precedents disagree, or one exists and Rust needs a decision | yes |
| `RUST-ONLY` | `none` | No precedent in either repo | yes |
| `OMIT` | any except `none` | No Rust analogue | none |

**Pattern vs tool.** "One formatter + one linter, in CI and in the pre-commit
hook" is a pattern; `ruff` and `oxlint`/`oxfmt` are tools. Swapping the tool is
`SUBSTITUTE`. Only changing the pattern is `OVERRIDE`.

## Prompt sections (enforced: exactly these, in order, outside code fences)

`## Objective` · `## Context` · `## Out of scope` · `## Couplings` (`- id: R##`,
`- owns: a, b`, `- consumes: R##: param; owner: param`) · `## Questions` ·
`## Required evidence` · `## Answer template` · `## Constraints` — spec §7.
Parameter names are lowercase-kebab slugs.

## Areas (13)

`ci-workflows` · `release-versioning` · `lint-format` · `static-analysis` ·
`testing-coverage` · `cli-framework-ux` · `config-env-logging` · `docs-system`
· `git-hooks-commit-hygiene` · `packaging-distribution` · `web-service` ·
`dev-experience-repo-hygiene` · `workspace-architecture`

## Checking

`scripts/check-research-tree.sh` (add `--require-owner-review` from Phase 3.5
on) enforces all of the above; `scripts/test-check-research-tree.sh` is its
regression suite (53 cases, each asserting the exit status).
