# Prompt migration verification

Verification date: 2026-09-04. Scope: final canonical P02 prompts and the
approved migration artifacts in this checkout. This audit was read-only for
canonical prompts; it did not rerun the migration helper or root-added tests.

## Results

- **Prompt structure:** 84 prompts inspected. Every prompt has exactly one
  `effort`, `engines`, `evidence-checks`, and `acceptance-after` coupling line,
  exactly one tier-guidance block, and eight `##` headings. The six Light IDs,
  53 Focused IDs, 25 Deep IDs, R38 three-engine exception, and R83/R84
  `acceptance-after: R71` mirror `research/EXECUTION.json`.
- **Bundle shape:** 51 bundle prompts contain the required `### Members`
  instruction, `#### <member name>` level, and complete ordered H5 crate
  field list. No legacy short member instruction remains.
- **Source preservation:** all `## Questions` sections match the source
  snapshot except the one authorized R79 OTel packaging clarification. No
  other prompt question changed. R42 has one blank separator before guidance;
  the maximum across all prompts is one and no duplicate blank run remains.
- **Dependency evidence:** `dependency-reconciliation.md` has 84 table rows
  and 94 exact cited excerpts. All 94 source locations and copied lines match
  the current canonical files byte-for-line at the cited line. Research graph:
  84 nodes, 69 edges, zero cycles. `acceptance-after` graph: zero cycles.
  No blanket `At resolution, run this item's empirical gate...` or `none
  beyond consumed` context gate remains. Owner-to-consumer references remain
  contextual; actual post-research prerequisites remain in `acceptance-after`.
- **Active-document links:** checked `research/RUNBOOK.md`, the dated spec,
  `PROJECTS.md`, and P02 `README.md`, `APPROVAL.md`, `acceptance-schema.md`,
  and `runner-guide.md`. Found 23 local links and zero missing targets.

## Commands

The audit used four inline Python 3 checks: prompt metadata/H2/bundle and
question-section comparison; reconciliation excerpt location/text matching;
active-document Markdown local-link resolution; and research/acceptance graph
cycle detection. Supporting inspections used `rg` for active documents,
relation text, and R42's guidance separator. No provider execution, native
Rust command, migration-helper run, or root-added test was performed for this
verification pass.
