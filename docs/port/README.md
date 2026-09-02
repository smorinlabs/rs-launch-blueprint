# Port analysis — method and vocabulary

Produced per `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md`.

## How the files relate

1. `areas/<area>.md` — raw evidence. One file per area, each a side-by-side
   table of how `py-launch-blueprint` and `ts-launch-blueprint` handle every
   feature in that area, with file references and any `TS_PORT_DECISIONS.md`
   ids that explain a difference. Written by survey agents; **no verdicts**.
2. `COMMONALITY.md` — the authoritative ledger. One row per feature, columns
   `Feature · Origin · Verdict · Notes`; verdicts from the closed set below.
   Override arguments live under `## Override arguments` as `### OV-nn`.
3. `PY_INVENTORY.md`, `TS_INVENTORY.md` — per-repo views derived from the
   same rows, for reading one source repo end to end.
4. `../../research/CLAUDE.md` — every row whose verdict needs research becomes
   an `R##` item with a prompt.

## Verdict vocabulary (closed set — enforced by `scripts/check-research-tree.sh`)

| Verdict | Meaning | Research prompt |
|---|---|---|
| `COMMON → REUSE` | Same in py and ts; language-neutral | none |
| `COMMON → SUBSTITUTE` | Same pattern in both; the tool is language-bound | yes |
| `COMMON → OVERRIDE (OV-nn)` | Same in both; a strong Rust-specific reason to change the *pattern* | yes — burden of proof on deviating |
| `DIVERGENT` | py and ts differ | yes |
| `RUST-ONLY` | No precedent in either repo | yes |
| `OMIT` | Python/TS-only, no Rust analogue | none |

**Pattern vs tool.** "One formatter + one linter, in CI and in the pre-commit
hook" is a pattern; `ruff` and `oxlint`/`oxfmt` are tools. Swapping the tool is
`SUBSTITUTE`. Only changing the pattern is `OVERRIDE`.

## Areas (12)

`ci-workflows` · `release-versioning` · `lint-format` · `static-analysis` ·
`testing-coverage` · `cli-framework-ux` · `config-env-logging` · `docs-system`
· `git-hooks-commit-hygiene` · `packaging-distribution` · `web-service` ·
`dev-experience-repo-hygiene`
