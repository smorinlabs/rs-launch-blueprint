# Area survey prompt (Phase 1) — filled per area

You are a read-only surveyor. You report; you never assign verdicts.

## Inputs
- `~/c/py-launch-blueprint` at commit `b08bccf` and `~/c/ts-launch-blueprint` at commit `cb1cbcb`. Read only. Do not run their tooling.
- `~/c/ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md` — the log that explains why the TS repo differs from the Python one. Cite ids (`D-014`) in the `ts-decisions` column.
- Your area: **{{AREA}}** — {{SCOPE}}
- Starter files (expand from here; grep both repos for anything else your area decides): {{STARTER_FILES}}

## Output — write exactly one file: `docs/port/areas/{{AREA}}.md`

```
# Area: {{AREA}}

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
```

Rules for the table:
1. One row per **atomic** feature. Split "pattern" from "tool": the row "one formatter and one linter, run in CI and in the pre-commit hook" is a pattern; the rows "formatter tool = ruff / oxfmt" and "linter tool = ruff / oxlint" are tools. If a row could be described two ways, split it.
2. `py` and `ts` cells: one or more citations `` `path:line` `` followed by ` — ` and how it is done, in ten words or fewer. Use `—` only when that repo has no instance of the feature.
3. `origin`: `same` (both repos, same way — the tool may differ, the pattern is the same), `different` (both repos, different ways), `py-only`, `ts-only`. Never `none`.
4. `ts-decisions`: the `D-###` ids that explain a difference, or `—`.
5. No `|` inside a cell. Leading and trailing pipes on every row. One table in the file.
6. Do not assign verdicts, recommend crates, or mention Rust tooling. Do not consult any other repository.

After the table, three sections with exactly these headings:

```
## Language-bound tools
- `<tool>` (py|ts) — <role it plays in this area>

## Cross-area parameters
- `<lowercase-kebab-slug>` — <why this area depends on a value decided elsewhere>

## Files read
- py: `<path>`
- ts: `<path>`
```

`Files read` lists **every** file you opened, one per line. A file you read that yielded no row gets ` — no feature: <reason>` appended. This list is the coverage manifest; an unlisted file is treated as unread.

Line numbers must be exact for the pinned commits — verify each with `sed -n '<line>p' <file>` before you write it. Do not estimate.

When done, run `bash scripts/check-area-file.sh docs/port/areas/{{AREA}}.md` and fix every FAIL before you finish. Reply with: the row count, the number of files read per repo, and any feature you were unsure how to split.
