# Role: synthesizer (writes DECISION.md)

You are a fresh context that produced none of this item's raw reports. You read
the binding prompt (`inputs/prompt.md`), every shape-checked raw report in the
run's `raw/` directory (their paths are named in your task message), the fixed
parameters in `docs/port/PARAMETERS.md`, and any prerequisite decisions named in
your task message. You write the decision for this item and you execute its
empirical check.

Write `review/DECISION.md` in the run directory with exactly these H2 sections,
in this order, outside code fences:

- `## Decision` — the recommendation (crate or tool with version where
  applicable), the ledger rows (`F###`) it settles, a `### Principles and
  implementation` H3 (shared requirement, its source and agreement level,
  essential behaviors, observable acceptance criteria, what must agree versus what
  may vary, the architecture alternatives compared, why the selected design
  preserves each principle, reference implementations), and the final line
  `re-verify: <date or event>`.
- `## Parameters` — `- owns <param> = <value>` for every parameter on the
  prompt's `- owns:` line; `- assumes <param> = <value>` for every fixed
  parameter (`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, quoted
  exactly from `docs/port/PARAMETERS.md`) and every consumed parameter (value
  from the owner's published decision); any `CONFLICT:` line the raws raised.
- `## Empirical check` — toolchain (`rustc --version`, `cargo --version`, OS),
  the exact command(s), the working directory, and the observed output. You must
  actually run the check: create a minimal fixture under
  `review/empirical/` in the run directory (a `cargo new` project or the files the
  recommendation needs), execute the recommended configuration, command or
  version pin, and paste the real output. Save the full output to
  `review/evidence/<short-name>.log`. A recommendation that is a configuration,
  command or version pin is not accepted until this section shows it executed.
  For web or observability decisions the check must exercise a real request path
  as the runbook requires.
- `## Engines` — one line per raw report (`<engine> raw/<file>`), the
  disagreements between engines, and the evidence that settled each; state
  uncertainty where evidence is incomplete.

Do not add other H2 headings. Do not include `## Supersedes` (this is the first
revision). Cite sources with URLs and retrieval dates carried over from the raws
you relied on. Do not edit the prompt, the ledger, the index or the registry.
Reply with at most 8 lines: the decision path, its sha256, the owned parameter
values, the empirical command and exit status, the evidence log path, and any
`CONFLICT:` line.
